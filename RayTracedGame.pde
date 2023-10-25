/*

 Ray Traced Game
 Evan D
 
 Controls are shown on screen, there are 3 interactable spheres
 No goal currently
 I don't know how to fix the black pixel bug :(
 No collision currently
 
 */



World world;
RenderBuffer renderBuffer;
Renderer renderer;
Camera cam;
Player player;

float playerSpeed = 2;
boolean w, a, s, d;

// Store position and angle to determine if we should refresh the view
ImageMetadata lastTransform;
ImageMetadata currentTransform;

DirectionalLight sun = new DirectionalLight(new PVector(.5, -1, .5), new Colour(235 / 255f, 235 / 255f, 210 / 255f), 1);

// The target size of the rendered world
int targetResX = 400;
int targetResY = 240;
int renderOffsetY = 70;

float fov = 75;
float renderJitter = 1f; // Helps with anti aliasing and such

RenderProfile activeProfile; // Stores render settings - see Library.pde

boolean accumulate = false; // Should we accumulate frames? Set automatically

Object movingObject; // What object we are moving right now,
float movingObjectDistance; // and how far away it is

Sphere glassSphere; // The objects we can move - not super clean, but last minute
Sphere glowSphere;
Sphere towerSphere;


void setup()
{
  size(400, 400);
  noStroke();
  ellipseMode(CENTER);

  initRenderer(); // Sets up the fast random and the renderer

  // Create all the world stuff
  world = new World(sun);
  cam = new Camera(new PVector(0, 0, 0), new PVector(0, 0, 0), fov, renderJitter);
  player = new Player(new PVector(0, 1, 0), cam, 0.5); //, 2.0, 0.5); // Unused height and radius here
  lastTransform = new ImageMetadata(); // Initalize these to empty for now
  currentTransform = new ImageMetadata();

  world.load(WorldData.env); // Load in the sections we want (all of them)
  world.load(WorldData.house); // For a proper game, you could load/unload sections
  world.load(WorldData.tower); //  as you go along to improve performance
  world.load(WorldData.spheres);

  spawnSpheres(); // The movable spheres
}

void initRenderer()
{
  rndSeed = (short)(random(1f) * Short.MAX_VALUE); // Init fast RNG
  updateActiveProfile(RenderProfiles.interactive); // Set default profile
  renderer = new Renderer(); // Create renderer
}

void spawnSpheres()
{
  // Create and add these 3 to the world,
  //  storing them to compare later
  glowSphere = new Sphere(new PVector(12, 5, 12), 5, Materials.glow);
  glassSphere = new Sphere(new PVector(7.5, 1, 7.5), 1, Materials.foggyGlass);
  towerSphere = new Sphere(new PVector(-6.5, 15 + 3.5, 5.5), 3.5, Materials.towerOrb);

  world.add(glowSphere);
  world.add(glassSphere);
  world.add(towerSphere);
}

void mousePressed()
{
  // If you click while in interactive mode
  if (mouseButton == LEFT && activeProfile == RenderProfiles.interactive)
  {
    if (movingObject != null)
    {
      // Drop the carried object
      movingObject = null;
      return;
    }

    Object obj = getMovingObject(); // The object we are looking at
    if (obj != null)
    {
      // Pick it up (if it exists)
      movingObject = obj;
      movingObjectDistance =obj.position.dist(cam.position);
    }
  }
}

void mouseWheel(MouseEvent event)
{
  if (movingObject == null)
    return;

  // Move the carried object forward/backward
  float distance = event.getCount() * -0.5;
  movingObjectDistance += distance;
}

void draw()
{
  updateTime(); // Time.pde
  tick(); // Update world
  resetFrame(); // Clear the frame and draw the background
  render3D(); // Render the world
  drawHUD(); // Render the HUD
}

void resetFrame()
{
  background(20);
  float padding = 5;
  fill(127); // Box around rendered image
  rect(0, renderOffsetY - padding, width, targetResY + padding * 2);
}

void render3D()
{
  // If I had time for some main menu, all I would have to do is
  //  set the active profile to null -> updateActiveProfile(null);
  if (activeProfile == null || renderBuffer == null)
    return;

  Image renderFrame = renderBuffer.getRenderFrame(); // Gets the next frame to be rendered to
  renderBuffer.setImageMetadata(player.position, cam.rotation); // Sets where this frame is going to be rendered
  currentTransform.set(player.position, cam.rotation); // Sets our current render position/angle

  accumulate = currentTransform.matches(lastTransform) && movingObject == null; // Accumulate if we are standing still (and not moving an object)
  // ^^^ Only changes samples and bounces, not the actual display (time constraint)

  lastTransform.set(player.position, cam.rotation); // Update to match current (to compare against next frame)

  // More samples/bounces if we are standing still (accumulating)
  int samples = accumulate ? activeProfile.samples_accumulate : activeProfile.samples_moving;
  int maxBounces = accumulate ? activeProfile.maxBounces_accumulate : activeProfile.maxBounces_moving;
  renderer.render(renderFrame, cam, world, samples, maxBounces);//, 1.0, 1.0); // Render the world to renderFrame

  renderBuffer.display(0, renderOffsetY); // Display the stored frames to the screen
}

void tick()
{
  //world.tick(); // Does nothing at the moment
  look(); // Rotate the camera
  player.move(playerSpeed, w, a, s, d); // Move the player
  player.tick(); // Aligns the camera to the player's position
  updateMovingObject(); // Update the object we are holding
}

void look()
{
  // If we are in interactive mode or click-dragging the mouse
  if (activeProfile == RenderProfiles.interactive || mousePressed && mouseButton == LEFT)
  {
    // No cursor when interacting
    if (activeProfile == RenderProfiles.interactive)
      noCursor();
    else // Hand when dragging
    cursor(HAND);

    float diffX = pmouseX - mouseX;
    float diffY = pmouseY - mouseY;
    cam.rotate(0, diffY); // Rotate the camera and player body
    player.rotate(-diffX);
  } else
  {
    cursor(HAND); // Draw a hand for non-interactive modes
  }
}

void updateMovingObject()
{
  if (movingObject == null)
    return;

  // Set it in front of the camera (max of 100 meters just because)
  movingObject.position = player.position.copy().add(cam.getForward().mult(min(movingObjectDistance, 100)));
}

Object getMovingObject()
{
  if (activeProfile != RenderProfiles.interactive)
    return null;

  // Send a ray out 100 meters (arbitrary)
  Hit hit = player.raycast(100, world);
  if (hit != null && (hit.object == glowSphere || hit.object == glassSphere || hit.object == towerSphere))
    return hit.object; // If we hit an object and it is one of the hardcoded objects (yuck) pick it up

  return null;
}


void drawHUD()
{
  fill(200);
  drawTitle(); // Self explanatory labels
  drawControls();
  drawMe(); // My name and details
  drawFPS();
  drawMovingObjectControls();
}

void drawTitle()
{
  // Ray-traced game!
  Font.draw(20, 10, 4, _r, _a, _y, _dash, _t, _r, _a, _c, _e, _d, _space, _g, _a, _m, _e, _exclam);
  // No proper title
  Font.draw(20, 45, 2, _lParen, _n, _o, _space, _p, _r, _o, _p, _e, _r, _space, _t, _i, _t, _l, _e, _period, _period, _period, _rParen);
}

void drawControls()
{
  // Controls:
  Font.draw(10, 320, 1, _c, _o, _n, _t, _r, _o, _l, _s, _colon);
  // WASD - Move
  Font.draw(10, 330, 1, _w, _a, _s, _d, _space, _dash, _space, _m, _o, _v, _e);
  // T - Toggle skybox
  Font.draw(200, 330, 1, _t, _space, _dash, _space, _t, _o, _g, _g, _l, _e, _space, _s, _k, _y, _b, _o, _x);
  // Mouse - Look (interactive)
  Font.draw(10, 340, 1, _m, _o, _u, _s, _e, _space, _dash, _space, _l, _o, _o, _k, _space, _lParen, _i, _n, _t, _e, _r, _a, _c, _t, _i, _v, _e, _rParen);
  // Click + Drag - Look (other modes)
  Font.draw(10, 350, 1, _c, _l, _i, _c, _k, _space, _plus, _space, _d, _r, _a, _g, _space, _dash, _space, _l, _o, _o, _k, _space, _lParen, _o, _t, _h, _e, _r, _space, _m, _o, _d, _e, _s, _rParen);
  // 1 - Interactive
  Font.draw(10, 360, 1, _1, _space, _dash, _space, _i, _n, _t, _e, _r, _a, _c, _t, _i, _v, _e);
  // 2 - Low quality render
  Font.draw(10, 370, 1, _2, _space, _dash, _space, _l, _o, _w, _space, _q, _u, _a, _l, _i, _t, _y, _space, _r, _e, _n, _d, _e, _r);
  // 3 - High quality render
  Font.draw(10, 380, 1, _3, _space, _dash, _space, _h, _i, _g, _h, _space, _q, _u, _a, _l, _i, _t, _y, _space, _r, _e, _n, _d, _e, _r);
  // 4 - Ultra quality render (super slow)
  Font.draw(10, 390, 1, _4, _space, _dash, _space, _u, _l, _t, _r, _a, _space, _q, _u, _a, _l, _i, _t, _y, _space, _r, _e, _n, _d, _e, _r,
    _space, _lParen, _s, _u, _p, _e, _r, _space, _s, _l, _o, _w, _rParen);
}

void drawMe()
{
  // Evan D
  Font.draw(250, 50, 1, _e, _v, _a, _n, _space, _d);
}

void drawFPS()
{
  float fps = 1f / dt_actual;
  Font.draw(320, 380, 1, _f, _p, _s, _colon, _space, Font.number(fps, 3));
}

void drawMovingObjectControls()
{
  if (movingObject == null)
  {
    // No held object
    Object obj = getMovingObject();
    if (obj != null)
    {
      // There is an object in front of us, draw some helpful tips
      fill(0); // Black background
      Font.draw(120, 200, 2, _l, _m, _b, _space, _t, _o, _space, _p, _i, _c, _k, _space, _u, _p); // LMB to pick up
      ellipse(targetResX / 2, targetResY / 2 + renderOffsetY, 7, 7); // Interact dot
      fill(255); // White foreground (moved slightly)
      Font.draw(120 + 1, 200 - 1, 2, _l, _m, _b, _space, _t, _o, _space, _p, _i, _c, _k, _space, _u, _p); // Same but white and moved slightly
      ellipse(targetResX / 2, targetResY / 2 + renderOffsetY, 5, 5);
    }
  } else
  {
    // We are holding an object, draw what we can do with it
    fill(0); // Background
    Font.draw(10, renderOffsetY + 5, 1.5, _l, _m, _b, _space, _dash, _space, _d, _r, _o, _p); // LMB - Drop
    Font.draw(10, renderOffsetY + 20, 1.5, _s, _c, _r, _o, _l, _l, _space, _dash, _space, _m, _o, _v, _e); // Scroll - Move
    Font.draw(10, renderOffsetY + 35, 1.5, _plus, _slash, _dash, _space, _dash, _space, _c, _h, _a, _n, _g, _e, _space, _s, _i, _z, _e); // +/- - Change size
    fill(255); // Foreground
    Font.draw(10 + 1, renderOffsetY + 5 - 1, 1.5, _l, _m, _b, _space, _dash, _space, _d, _r, _o, _p); // LMB - Drop
    Font.draw(10 + 1, renderOffsetY + 20 - 1, 1.5, _s, _c, _r, _o, _l, _l, _space, _dash, _space, _m, _o, _v, _e); // Scroll - Move
    Font.draw(10 + 1, renderOffsetY + 35 - 1, 1.5, _plus, _slash, _dash, _space, _dash, _space, _c, _h, _a, _n, _g, _e, _space, _s, _i, _z, _e); // +/- - Change size
  }
}



void updateActiveProfile(RenderProfile profile)
{
  // Are we trying to set the exact same one?
  if (activeProfile == profile) return;

  activeProfile = profile;

  // Drop our held object
  movingObject = null;

  // No render profile (for menus and stuff)
  if (profile == null)
  {
    frameRate(60);
    renderBuffer = null;
    return;
  }

  frameRate(activeProfile.fps);

  // Recreate the render buffer with the proper resolution
  int renderResX = targetResX / activeProfile.renderScale;
  int renderResY = targetResY / activeProfile.renderScale;
  renderBuffer = new RenderBuffer(renderResX, renderResY, activeProfile.numBufferedFrames, activeProfile.renderScale);
}



void keyPressed()
{
  // Player movement
  if (key == 'w' || key == 'W') w = true;
  if (key == 'a' || key == 'A') a = true;
  if (key == 's' || key == 'S') s = true;
  if (key == 'd' || key == 'D') d = true;

  // Render profiles
  if (key == '1')
    updateActiveProfile(RenderProfiles.interactive);
  if (key == '2')
    updateActiveProfile(RenderProfiles.low);
  if (key == '3')
    updateActiveProfile(RenderProfiles.high);
  if (key == '4')
    updateActiveProfile(RenderProfiles.ultra);

  // Skybox (looks cool)
  if (key == 't' || key == 'T')
    renderer.renderSkybox = !renderer.renderSkybox;

  // Moving object controls
  if (movingObject != null)
  {
    Sphere sp = (Sphere)movingObject; // Yuck but not sure if instanceof is allowed
    if (key == '=')
      sp.radius += 0.2;
    if (key == '-')
      sp.radius = max(sp.radius - 0.2, 0.02);
  }
}

void keyReleased()
{
  if (key == 'w' || key == 'W') w = false;
  if (key == 'a' || key == 'A') a = false;
  if (key == 's' || key == 'S') s = false;
  if (key == 'd' || key == 'D') d = false;
}



/*
// BASIC RAYTRACING PSEUDOCODE
 // https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-ray-tracing/implementing-the-raytracing-algorithm.html
 
 for (int j = 0; j < imageHeight; ++j) {
 for (int i = 0; i < imageWidth; ++i) {
 // compute primary ray direction
 Ray primRay;
 computePrimRay(i, j, &primRay);
 // shoot prim ray in the scene and search for the intersection
 Point pHit;
 Normal nHit;
 float minDist = INFINITY;
 Object object = NULL;
 for (int k = 0; k < objects.size(); ++k) {
 if (Intersect(objects[k], primRay, &pHit, &nHit)) {
 float distance = Distance(eyePosition, pHit);
 if (distance < minDistance) {
 object = objects[k];
 minDistance = distance;  //update min distance
 }
 }
 }
 if (object != NULL) {
 // compute illumination
 Ray shadowRay;
 shadowRay.direction = lightPosition - pHit;
 bool isShadow = false;
 for (int k = 0; k < objects.size(); ++k) {
 if (Intersect(objects[k], shadowRay)) {
 isInShadow = true;
 break;
 }
 }
 }
 if (!isInShadow)
 pixels[i][j] = object->color * light.brightness;
 else
 pixels[i][j] = 0;
 }
 }
 */
