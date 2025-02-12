const String geometryDrawingSpec = '''
{
  "instructions": {
    "timing": [
      {
        "stage": "draw_grid",
        "startTime": 0,
        "endTime": 6,
        "description": "Drawing a 3x4 grid of dots representing groups",
        "easing": "easeIn"
      },
      {
        "stage": "highlight",
        "startTime": 6,
        "endTime": 12,
        "description": "Highlighting one group to show one row equals 4",
        "easing": "linear"
      },
      {
        "stage": "equation",
        "startTime": 12,
        "endTime": 20,
        "description": "Displaying the multiplication equation 3 x 4 = 12",
        "easing": "easeOut"
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "draw_grid",
          "vertices": [
            { "x": 60, "y": 100 },
            { "x": 210, "y": 200 }
          ],
          "path": "moveTo(65,100) arcTo(60,100,10,10,0,6.28,true) close() moveTo(115,100) arcTo(110,100,10,10,0,6.28,true) close() moveTo(165,100) arcTo(160,100,10,10,0,6.28,true) close() moveTo(215,100) arcTo(210,100,10,10,0,6.28,true) close() moveTo(65,150) arcTo(60,150,10,10,0,6.28,true) close() moveTo(115,150) arcTo(110,150,10,10,0,6.28,true) close() moveTo(165,150) arcTo(160,150,10,10,0,6.28,true) close() moveTo(215,150) arcTo(210,150,10,10,0,6.28,true) close() moveTo(65,200) arcTo(60,200,10,10,0,6.28,true) close() moveTo(115,200) arcTo(110,200,10,10,0,6.28,true) close() moveTo(165,200) arcTo(160,200,10,10,0,6.28,true) close() moveTo(215,200) arcTo(210,200,10,10,0,6.28,true) close()",
          "style": "fill",
          "strokeWidth": 2,
          "color": "#000000",
          "fadeInRange": [0, 6]
        },
        {
          "id": "highlight",
          "vertices": [
            { "x": 55, "y": 95 },
            { "x": 215, "y": 105 }
          ],
          "path": "moveTo(55,95) lineTo(215,95) lineTo(215,105) lineTo(55,105) close()",
          "style": "stroke",
          "strokeWidth": 3,
          "color": "#FF0000",
          "fadeInRange": [6, 12]
        },
        {
          "id": "equation",
          "vertices": [
            { "x": 100, "y": 300 },
            { "x": 200, "y": 300 }
          ],
          "path": "moveTo(100,300) lineTo(200,300)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#0000FF",
          "fadeInRange": [12, 20]
        }
      ],
      "labels": [
        {
          "id": "draw_grid",
          "text": "3 groups of 4",
          "position": { "x": 80, "y": 70 },
          "color": "#000000",
          "fadeInRange": [0, 6],
          "handwritten": true
        },
        {
          "id": "highlight",
          "text": "one group = 4",
          "position": { "x": 220, "y": 100 },
          "color": "#FF0000",
          "fadeInRange": [6, 12],
          "handwritten": true
        },
        {
          "id": "equation",
          "text": "3 x 4 = 12",
          "position": { "x": 100, "y": 270 },
          "color": "#0000FF",
          "fadeInRange": [12, 20],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "Basic multiplication means repeated addition. Here we see three groups of four dots, which add up to twelve.",
      "pacing": {
        "initialDelay": 0,
        "betweenStages": 0,
        "finalDelay": 2
      }
    }
  }
}

''';
