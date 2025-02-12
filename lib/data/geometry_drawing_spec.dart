const String geometryDrawingSpec = '''
{
  "instructions": {
    "timing": [
      {
        "stage": "draw_boxes",
        "startTime": 0,
        "endTime": 5,
        "description": "Draw three simple boxes representing x, u, and y."
      },
      {
        "stage": "draw_arrows",
        "startTime": 5,
        "endTime": 10,
        "description": "Draw arrows connecting the boxes to show the flow from x to u and from u to y."
      },
      {
        "stage": "draw_labels",
        "startTime": 10,
        "endTime": 15,
        "description": "Label the boxes and arrows with simple text."
      },
      {
        "stage": "draw_explanation",
        "startTime": 15,
        "endTime": 20,
        "description": "Display a simple explanation of the chain rule concept."
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_boxes",
          "vertices": [
            { "x": 20, "y": 100 },
            { "x": 100, "y": 100 },
            { "x": 100, "y": 150 },
            { "x": 20, "y": 150 },
            { "x": 120, "y": 100 },
            { "x": 200, "y": 100 },
            { "x": 200, "y": 150 },
            { "x": 120, "y": 150 },
            { "x": 220, "y": 100 },
            { "x": 300, "y": 100 },
            { "x": 300, "y": 150 },
            { "x": 220, "y": 150 }
          ],
          "path": "moveTo(20,100) lineTo(100,100) lineTo(100,150) lineTo(20,150) close() moveTo(120,100) lineTo(200,100) lineTo(200,150) lineTo(120,150) close() moveTo(220,100) lineTo(300,100) lineTo(300,150) lineTo(220,150) close()",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#000000",
          "fadeInRange": [0, 5]
        },
        {
          "id": "draw_arrows",
          "vertices": [
            { "x": 100, "y": 125 },
            { "x": 120, "y": 125 },
            { "x": 200, "y": 125 },
            { "x": 220, "y": 125 }
          ],
          "path": "moveTo(100,125) lineTo(120,125) moveTo(112,119) lineTo(120,125) lineTo(112,131) moveTo(200,125) lineTo(220,125) moveTo(212,119) lineTo(220,125) lineTo(212,131)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#FF0000",
          "fadeInRange": [5, 10]
        }
      ],
      "labels": [
        {
          "id": "label_x",
          "text": "x",
          "position": { "x": 60, "y": 120 },
          "color": "#000000",
          "fadeInRange": [10, 15],
          "handwritten": true
        },
        {
          "id": "label_u",
          "text": "u",
          "position": { "x": 160, "y": 120 },
          "color": "#000000",
          "fadeInRange": [10, 15],
          "handwritten": true
        },
        {
          "id": "label_y",
          "text": "y",
          "position": { "x": 260, "y": 120 },
          "color": "#000000",
          "fadeInRange": [10, 15],
          "handwritten": true
        },
        {
          "id": "label_step1",
          "text": "step 1: x changes to u",
          "position": { "x": 50, "y": 200 },
          "color": "#000000",
          "fadeInRange": [10, 15],
          "handwritten": true
        },
        {
          "id": "label_step2",
          "text": "step 2: u changes to y",
          "position": { "x": 75, "y": 250 },
          "color": "#000000",
          "fadeInRange": [10, 15],
          "handwritten": true
        },
        {
          "id": "label_explanation",
          "text": "chain rule: overall change in y comes from both steps.",
          "position": { "x": 10, "y": 300 },
          "color": "#000000",
          "fadeInRange": [15, 20],
          "handwritten": true
        },
                {
          "id": "label_explanation",
          "text": "in y comes from both steps.",
          "position": { "x": 20, "y": 350 },
          "color": "#000000",
          "fadeInRange": [15, 20],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "Let's learn the chain rule in a simple way. Imagine three boxes: one for x, one for u, and one for y. When x changes, it causes a change in u, and then u causes a change in y. This means that the overall change in y is a result of both steps working together. That's the basic idea behind the chain rule.",
      "pacing": {
        "initialDelay": 1,
        "betweenStages": 2,
        "finalDelay": 2
      }
    }
  }
}

''';
