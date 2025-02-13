const String geometryDrawingSpec = '''{
  "instructions": {
    "timing": [
      {
        "stage": "first_set",
        "startTime": 0,
        "endTime": 3,
        "description": "Drawing 2 apples to represent the number 2.",
        "easing": "easeIn"
      },
      {
        "stage": "second_set",
        "startTime": 3,
        "endTime": 6,
        "description": "Drawing 3 apples to represent the number 3.",
        "easing": "linear"
      },
      {
        "stage": "total_equation",
        "startTime": 6,
        "endTime": 9,
        "description": "Displaying the equation 2 + 3 = 5.",
        "easing": "easeOut"
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "first_set",
          "vertices": [
            { "x": 60, "y": 150 },
            { "x": 110, "y": 150 }
          ],
          "path": "moveTo(70,150) arcTo(50,140,20,20,0,6.28,true) close() moveTo(120,150) arcTo(100,140,20,20,0,6.28,true) close()",
          "style": "fill",
          "strokeWidth": 2,
          "color": "#FF0000",
          "fadeInRange": [0, 3]
        },
        {
          "id": "second_set",
          "vertices": [
            { "x": 60, "y": 250 },
            { "x": 110, "y": 250 },
            { "x": 160, "y": 250 }
          ],
          "path": "moveTo(70,250) arcTo(50,240,20,20,0,6.28,true) close() moveTo(120,250) arcTo(100,240,20,20,0,6.28,true) close() moveTo(170,250) arcTo(150,240,20,20,0,6.28,true) close()",
          "style": "fill",
          "strokeWidth": 2,
          "color": "#FF0000",
          "fadeInRange": [3, 6]
        },
        {
          "id": "total_equation",
          "vertices": [
            { "x": 60, "y": 350 },
            { "x": 260, "y": 350 }
          ],
          "path": "moveTo(60,350) lineTo(260,350)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#0000FF",
          "fadeInRange": [6, 9]
        }
      ],
      "labels": [
        {
          "id": "first_set",
          "text": "2 apples",
          "position": { "x": 55, "y": 100 },
          "color": "#000000",
          "fadeInRange": [0, 3],
          "handwritten": true
        },
        {
          "id": "second_set",
          "text": "3 apples ?",
          "position": { "x": 55, "y": 265 },
          "color": "#000000",
          "fadeInRange": [3, 6],
          "handwritten": true
        },
        {
          "id": "total_equation",
          "text": "2 + 3 = 5",
          "position": { "x": 120, "y": 310 },
          "color": "#000000",
          "fadeInRange": [6, 9],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "Let's add some apples! Look, here are 2 apples. Now, we add 3 more apples. Count them all together: 2 plus 3 makes 5! Great job!",
      "pacing": {
        "initialDelay": 0,
        "betweenStages": 0,
        "finalDelay": 2
      }
    }
  }
}''';
