const WebSocket = require('ws');

const wss = new WebSocket.Server({ noServer: true });
const connections = new Set();

wss.on('connection', function connection(ws) {
    connections.add(ws);
    console.log('Client connected');
    
    ws.on('message', function message(data) {
        // Пересылаем команды всем клиентам
        connections.forEach(client => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(data);
            }
        });
    });

    ws.on('close', function() {
        connections.delete(ws);
        console.log('Client disconnected');
    });
});

exports.handler = async (event, context) => {
    if (event.requestContext) {
        try {
            const { upgrade, setStatusCode, setBody, end } = event.requestContext;
            if (upgrade) {
                wss.handleUpgrade(event, event.requestContext.socket, 
                    event.requestContext.head, (ws) => {
                    wss.emit('connection', ws, event);
                });
                return { statusCode: 101 };
            }
        } catch (err) {
            return { statusCode: 500, body: 'Error: ' + err.message };
        }
    }
    return { statusCode: 400, body: 'Not WebSocket' };
};