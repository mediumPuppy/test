const String geometryDrawingSpec = '''{
  "instructions": {
    "timing": [
      {
        "stage": "draw_curve",
        "startTime": 0,
        "endTime": 2,
        "description": "Drawing the gentle hill curve."
      },
      {
        "stage": "draw_secant",
        "startTime": 2,
        "endTime": 4,
        "description": "Drawing the secant line connecting two points on the curve."
      },
      {
        "stage": "draw_tangent",
        "startTime": 4,
        "endTime": 6,
        "description": "Drawing the tangent line as the secant line converges."
      },
      {
        "stage": "draw_labels",
        "startTime": 6,
        "endTime": 8,
        "description": "Adding labels to key elements."
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_curve",
          "vertices": [
            { "x": 40, "y": 360 },
            { "x": 140, "y": 420 },
            { "x": 280, "y": 360 }
          ],
          "path": "moveTo(40,360) quadraticBezierTo(140,420,280,360)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#1E90FF",
          "fadeInRange": [0, 2]
        },
        {
          "id": "draw_secant",
          "vertices": [
            { "x": 81.6, "y": 379.2 },
            { "x": 174.4, "y": 388.8 }
          ],
          "path": "moveTo(81.6,379.2) lineTo(174.4,388.8)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#FF4500",
          "fadeInRange": [2, 4]
        },
        {
          "id": "draw_tangent",
          "vertices": [
            { "x": 50, "y": 380.9 },
            { "x": 250, "y": 401.6 }
          ],
          "path": "moveTo(50,380.9) lineTo(250,401.6)",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#32CD32",
          "fadeInRange": [4, 6]
        }
      ],
      "labels": [
        {
          "id": "draw_curve",
          "text": "Curve",
          "position": { "x": 160, "y": 310 },
          "color": "#000000",
          "fadeInRange": [0, 2],
          "handwritten": true
        },
        {
          "id": "draw_secant",
          "text": "Secant",
          "position": { "x": 128, "y": 364 },
          "color": "#000000",
          "fadeInRange": [2, 4],
          "handwritten": true
        },
        {
          "id": "draw_tangent",
          "text": "Tangent",
          "position": { "x": 110, "y": 450 },
          "color": "#000000",
          "fadeInRange": [4, 6],
          "handwritten": true
        },
        {
          "id": "point_P",
          "text": "P",
          "position": { "x": 66, "y": 369 },
          "color": "#FF4500",
          "fadeInRange": [2, 4],
          "handwritten": true
        },
        {
          "id": "point_Q",
          "text": "Q",
          "position": { "x": 184, "y": 400 },
          "color": "#FF4500",
          "fadeInRange": [2, 4],
          "handwritten": true
        },
        {
          "id": "point_T",
          "text": "T",
          "position": { "x": 116, "y": 410 },
          "color": "#32CD32",
          "fadeInRange": [4, 6],
          "handwritten": true
        },
        {
          "id": "label_derivative",
          "text": "Derivative = slope at T",
          "position": { "x": 260, "y": 410 },
          "color": "#32CD32",
          "fadeInRange": [4, 6],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "This lesson illustrates how the derivative of a curve at a point is the slope of the tangent line. First, we draw a gentle hill. Then, we mark two points on the curve and connect them with a secant line. As one point slides closer, the secant line becomes the tangent line, representing the derivative.",
      "pacing": {
        "initialDelay": 1,
        "betweenStages": 2,
        "finalDelay": 2
      }
    }
  }
}''';
