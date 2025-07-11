const express = require('express');
const axios = require('axios');
const base64 = require('base-64');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Enable CORS for all origins (or specify origins like 'http://localhost:53318')
app.use(cors({
  origin: '*',
  methods: ['GET', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept'],
}));

// Middleware to parse JSON bodies
app.use(express.json());

// Endpoint to get CurrentState for a device
app.get('/api/currentstate/:deviceId', async (req, res) => {
  const { deviceId } = req.params;
  const azureFunctionUrl = 'https://getcurrentstatepantry-hdbzh8fbbcesaqds.westus2-01.azurewebsites.net/api/HttpTrigger1';
  

  try {
    // Call the Azure Function HTTP trigger
    const response = await axios.get(azureFunctionUrl, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const documents = response.data;

    if (!Array.isArray(documents) || documents.length === 0) {
      return res.status(400).json({ error: 'No data returned from Azure Function' });
    }

    // Decode all documents and filter by deviceId
    const deviceDocs = documents
      .map(doc => {
        try {
          const decoded = base64.decode(doc.Body);
          const payload = JSON.parse(decoded);
          return { ...doc, decodedPayload: payload };
        } catch (e) {
          console.error('Error decoding document:', e.message, doc.Body);
          return null;
        }
      })
      .filter(doc => doc && doc.decodedPayload.deviceId === deviceId);

    if (deviceDocs.length === 0) {
      return res.status(404).json({ error: `No data found for device ${deviceId}` });
    }

    // Find the initial state (isInitial: true)
    const initialDoc = deviceDocs.find(doc => doc.decodedPayload.isInitial === true);

    if (!initialDoc) {
      return res.status(404).json({ error: `Initial state not found for device ${deviceId}` });
    }

    const initialPayload = initialDoc.decodedPayload;
    const initialChanges = initialPayload.changes;

    // Filter incremental updates (isInitial: null) and sort by timestamp
    const incrementalDocs = deviceDocs
      .filter(doc => doc.decodedPayload.isInitial === null)
      .sort((a, b) => {
        const timeA = new Date(a.decodedPayload.timestamp).getTime();
        const timeB = new Date(b.decodedPayload.timestamp).getTime();
        return timeA - timeB;
      });

    // Construct CurrentState starting from the initial state
    let currentState = {
      id: `state_${deviceId}`,
      deviceId: deviceId,
      lastUpdated: initialPayload.timestamp,
      totalWeight: initialChanges.totalWeight,
      items: {},
      temperature: initialChanges.environment?.temperature || null,
      isDisturbed: initialChanges.environment?.isDisturbed || false,
      batteryLevel: initialChanges.status?.batteryLevel || null,
      currentHeight: initialPayload.currentHeight || null, // Initialize currentHeight
      totalHeight: initialPayload.totalHeight || null     // Initialize totalHeight
    };

    // Initialize items from initial state, including enriched fields and bestBefore
    if (initialChanges.items) {
      initialChanges.items.forEach((item) => {
        currentState.items[item.id] = {
          id: item.id,
          weight: item.weight,
          bestBefore: item.bestBefore || null, // Include bestBefore
          description: item.description,
          category: item.category,
          unit: item.unit,
          weightPerUnit: item.weightPerUnit
        };
      });
    }

    // Apply all incremental updates in chronological order
    for (const doc of incrementalDocs) {
      const currentPayload = doc.decodedPayload;
      const currentChanges = currentPayload.changes;

      // Update lastUpdated timestamp
      currentState.lastUpdated = currentPayload.timestamp;

      // Apply changes from the current incremental update
      if (currentChanges.totalWeight !== null) {
        currentState.totalWeight = currentChanges.totalWeight;
      }
      if (currentChanges.items) {
        currentChanges.items.forEach((item) => {
          if (item.removed === true) {
            delete currentState.items[item.id];
          } else if (item.weight !== null) {
            // Update the weight but preserve enriched fields and bestBefore
            if (currentState.items[item.id]) {
              currentState.items[item.id].weight = item.weight;
              // bestBefore remains unchanged unless the update explicitly provides it (not expected in this schema)
            } else {
              // If the item is new (not in initial state), include it with enriched fields
              currentState.items[item.id] = {
                id: item.id,
                weight: item.weight,
                bestBefore: item.bestBefore || null,
                description: item.description,
                category: item.category,
                unit: item.unit,
                weightPerUnit: item.weightPerUnit
              };
            }
          }
        });
      }
      if (currentChanges.environment) {
        if (currentChanges.environment.temperature !== null) {
          currentState.temperature = currentChanges.environment.temperature;
        }
        if (currentChanges.environment.isDisturbed !== null) {
          currentState.isDisturbed = currentChanges.environment.isDisturbed;
        }
      }
      if (currentChanges.status && currentChanges.status.batteryLevel !== null) {
        currentState.batteryLevel = currentChanges.status.batteryLevel;
      }
      if (currentPayload.currentHeight !== null) {
        currentState.currentHeight = currentPayload.currentHeight;
      }
      // totalHeight is only set in the initial state, so no update needed here
    }

    // Convert items object to array
    currentState.items = Object.values(currentState.items);

    // Return the consolidated CurrentState
    res.json(currentState);
  } catch (error) {
    console.error('Error fetching or processing data:', error.message);
    res.status(500).json({ error: 'Failed to retrieve CurrentState', details: error.message });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});