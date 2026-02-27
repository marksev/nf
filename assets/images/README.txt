Wave Rider – Image Assets
==========================

The game currently renders all visuals programmatically using Flutter's Canvas
API, so no image files are required to run.

If you want to replace the drawn graphics with actual sprites, add your files
here and load them in the corresponding component using:

  final sprite = await gameRef.loadSprite('filename.png');

Then call sprite.render(canvas, ...) inside the component's render() method.

Suggested sprites (all in PNG format, ideally 2× for retina):
  surfer.png         – surfer on board, facing right  (128×96 px)
  shark.png          – shark with dorsal fin           (160×96 px)
  rock.png           – jagged rock                     (96×128 px)
  coin.png           – gold coin / star                (64×64 px)
  wave_tile.png      – tileable wave strip             (256×64 px)
  background.png     – sky + horizon                   (1024×256 px)
