//This is Azure Function code for reference

const { CosmosClient } = require("@azure/cosmos");

module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');

    const endpoint = "";
    const key = "";
    const databaseId = "cosmicworks";
    const updatesContainerId = "products";
    const masterContainerId = "PantryMaster";

    context.log('Going to retrieve data...');

    try {
        // Initialize Cosmos DB client
        const client = new CosmosClient({ endpoint, key });
        const database = client.database(databaseId);

        // Access IncrementalUpdates container
        const updatesContainer = database.container(updatesContainerId);
        const { resources: updateResources } = await updatesContainer.items.readAll().fetchAll();
        context.log('Retrieved IncrementalUpdates:', JSON.stringify(updateResources, null, 2));

        // Access PantryMaster container
        const masterContainer = database.container(masterContainerId);
        const { resources: masterResources } = await masterContainer.items.readAll().fetchAll();
        context.log('Retrieved PantryMaster:', JSON.stringify(masterResources, null, 2));

        // Create a lookup map for PantryMaster data (keyed by item id)
        const masterLookup = {};
        masterResources.forEach(masterItem => {
            const itemId = masterItem.id; // e.g., "I1", "I2"
            masterLookup[itemId] = {
                description: masterItem.description || 'Unknown',
                category: masterItem.category || 'Uncategorized',
                unit: masterItem.unit || 'unit',
                weightPerUnit: masterItem.weightPerUnit || 0
            };
            context.log(`Added to masterLookup: ${itemId}`, JSON.stringify(masterLookup[itemId]));
        });
        context.log('PantryMaster Lookup:', JSON.stringify(masterLookup, null, 2));

        // Process each IncrementalUpdates document
        const enrichedResources = updateResources.map(update => {
            // Decode the Base64-encoded Body
            let decodedBody = Buffer.from(update.Body, 'base64').toString('utf-8');
            context.log('Decoded Body for update:', update.id, decodedBody);

            // Replace Python-style booleans (True/False) with JSON-style booleans (true/false)
            decodedBody = decodedBody.replace(/\bTrue\b/g, 'true').replace(/\bFalse\b/g, 'false');
            context.log('Fixed Body for update:', update.id, decodedBody);

            // Parse the decoded Body as JSON
            const bodyData = JSON.parse(decodedBody);

            // Enrich the items in the Body's c.i array (if it exists)
            const changes = bodyData.c || {};
            if (changes.i && Array.isArray(changes.i)) {
                context.log('Processing items for update:', update.id);
                changes.i = changes.i.map(item => {
                    const itemId = item.id; // e.g., "I1"
                    const masterData = masterLookup[itemId] || {};
                    context.log(`Enriching item ${itemId}:`, JSON.stringify(masterData));

                    // Enrich the item with PantryMaster details and rename keys
                    return {
                        id: item.id,
                        weight: item.w || null,
                        removed: item.r || null,
                        bestBefore: item.bb || null, // Preserve bestBefore if present (in initial states)
                        description: masterData.description,
                        category: masterData.category,
                        unit: masterData.unit,
                        weightPerUnit: masterData.weightPerUnit
                    };
                });
            } else {
                context.log('No items to process for update:', update.id);
            }

            // Transform the compact keys to expanded keys
            const transformedData = {
                deviceId: bodyData.d || null,
                timestamp: bodyData.t || null,
                isInitial: bodyData.isInitial || null,
                messageId: bodyData.id || null,
                changes: {
                    totalWeight: changes.w || null,
                    items: changes.i || [],
                    environment: changes.e ? {
                        temperature: changes.e.t || null,
                        isDisturbed: changes.e.d || null
                    } : { temperature: null, isDisturbed: null },
                    status: changes.s ? {
                        batteryLevel: changes.s.b || null,
                        errorCode: changes.s.e || null
                    } : { batteryLevel: null, errorCode: null }
                },
                currentHeight: bodyData.ch || null, // Map ch to currentHeight
                totalHeight: bodyData.th || null   // Map th to totalHeight
            };

            context.log('Transformed data:', JSON.stringify(transformedData, null, 2));

            // Re-encode the Body as Base64
            const enrichedBody = Buffer.from(JSON.stringify(transformedData), 'utf-8').toString('base64');

            // Return the updated document with the enriched Body
            return {
                ...update,
                Body: enrichedBody
            };
        });

        context.log('Enriched data:', JSON.stringify(enrichedResources, null, 2));

        // Return the enriched response
        context.res = {
            status: 200,
            body: JSON.stringify(enrichedResources),
        };
    } catch (error) {
        context.log('Error:', error.message);
        context.res = {
            status: 500,
            body: JSON.stringify({ error: 'Failed to process request', details: error.message }),
        };
    }
};
