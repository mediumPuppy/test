const String geometryDrawingSpec = '''
{
  "instructions": {
    "timing": [
      {
        "stage": "introduction",
        "startTime": 0,
        "endTime": 5,
        "description": "we will explore how multiplication is repeated addition",
        "easing": "linear"

      },
      {
        "stage": "exampleRow1",
        "startTime": 5,
        "endTime": 10,
        "description": "first row of 3 items",
        "easing": "linear"
      },
      {
        "stage": "exampleRow2",
        "startTime": 10,
        "endTime": 15,
        "description": "second row of 3 items",
        "easing": "linear"
      },
      {
        "stage": "summary",
        "startTime": 15,
        "endTime": 20,
        "description": "final explanation",
        "easing": "linear"
      }
    ],
    "drawing": {
      "shapes": [
        {
          "id": "exampleRow1",
          "vertices": [
            { "x": 90, "y": 60 },
            { "x": 50, "y": 40 }
          ],
          "path": "moveTo(90,60) arcTo(50,40,40,40,0,6.28319,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#5588aa",
          "fadeInRange": [5, 6]
        },
        {
          "id": "exampleRow1",
          "vertices": [
            { "x": 130, "y": 60 },
            { "x": 90, "y": 40 }
          ],
          "path": "moveTo(130,60) arcTo(90,40,40,40,0,6.28319,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#5588aa",
          "fadeInRange": [5, 6]
        },
        {
          "id": "exampleRow1",
          "vertices": [
            { "x": 170, "y": 60 },
            { "x": 130, "y": 40 }
          ],
          "path": "moveTo(170,60) arcTo(130,40,40,40,0,6.28319,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#5588aa",
          "fadeInRange": [5, 6]
        },
        {
          "id": "exampleRow2",
          "vertices": [
            { "x": 90, "y": 100 },
            { "x": 50, "y": 80 }
          ],
          "path": "moveTo(90,100) arcTo(50,80,40,40,0,6.28319,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#5588aa",
          "fadeInRange": [10, 11]
        },
        {
          "id": "exampleRow2",
          "vertices": [
            { "x": 130, "y": 100 },
            { "x": 90, "y": 80 }
          ],
          "path": "moveTo(130,100) arcTo(90,80,40,40,0,6.28319,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#5588aa",
          "fadeInRange": [10, 11]
        },
        {
          "id": "exampleRow2",
          "vertices": [
            { "x": 170, "y": 100 },
            { "x": 130, "y": 80 }
          ],
          "path": "moveTo(170,100) arcTo(130,80,40,40,0,6.28319,true)",
          "style": "stroke",
          "strokeWidth": 2,
          "color": "#5588aa",
          "fadeInRange": [10, 11]
        }
      ],
      "labels": [
        {
          "id": "introduction",
          "text": "basic multiplication",
          "position": { "x": 20, "y": 30 },
          "color": "#444444",
          "fadeInRange": [0, 1],
          "handwritten": true
        },
        {
          "id": "exampleRow1",
          "text": "3 items",
          "position": { "x": 180, "y": 60 },
          "color": "#444444",
          "fadeInRange": [5, 6],
          "handwritten": true
        },
        {
          "id": "exampleRow2",
          "text": "another 3",
          "position": { "x": 180, "y": 100 },
          "color": "#444444",
          "fadeInRange": [10, 11],
          "handwritten": true
        },
        {
          "id": "summary",
          "text": "2 x 3 = 6",
          "position": { "x": 70, "y": 150 },
          "color": "#444444",
          "fadeInRange": [15, 16],
          "handwritten": true
        }
      ]
    },
    "speech": {
      "script": "multiplication is repeated addition. here, we show 2 rows of 3 items each, giving 6 total. first, we see 3 items in a row. then another row of 3. counting them all gives us 6, which is 2 x 3. this simple idea extends to larger numbers, where we just keep adding groups. practice and you will see how quickly you can multiply.",
      "pacing": {
        "initialDelay": 0,
        "betweenStages": 1,
        "finalDelay": 0
      }
    }
  }
}

''';
