
// This file just stores world/level data

WorldData WorldData = new WorldData(); // Global accessor

class WorldData
{
  WorldSegment env; // The environment (hills, floor)
  WorldSegment tower;
  WorldSegment house; 
  WorldSegment spheres; // The walls near the spheres

  WorldData()
  {
    initEnv();
    initTower();
    initHouse();
    initSpheres();
  }

  void initEnv()
  {
    Plane ground = new Plane(new PVector(0, 1, 0), Materials.grass);

    Sphere mountain1 = new Sphere(new PVector(-100, -40, -30), 65, Materials.grass);
    Sphere mountain2 = new Sphere(new PVector(100, -70, 120), 100, Materials.grass);
    Sphere mountain3 = new Sphere(new PVector(-20, -130, 120), 150, Materials.grass);
    Sphere mountain4 = new Sphere(new PVector(20, -270, -220), 300, Materials.grass);

    env = new WorldSegment(ground, mountain1, mountain2, mountain3, mountain4);
  }

  void initTower()
  {
    float x = -6.5;
    float z = 5.5;
    float tallHeight = 15;
    float midHeight = 10;
    float shortHeight = 5;
    Box center = new Box(new PVector(x, tallHeight / 2, z), new PVector(1, tallHeight, 1), Materials.black); // The tall part
    Box base = new Box(new PVector(x, midHeight / 2, z), new PVector(2, midHeight, 2), Materials.black); // The middle height block
    Box horizontal = new Box(new PVector(x, shortHeight / 2, z), new PVector(3, shortHeight, 1), Materials.black); // Left-right thing
    Box vertical = new Box(new PVector(x, shortHeight / 2, z), new PVector(1, shortHeight, 3), Materials.black); // Top-bottom thing

    //Sphere eyeIris = new Sphere(new PVector(x, tallHeight + eyeRadiusLarge, z + eyeRadiusLarge + eyeRadiusSmall), eyeRadiusSmall, Materials.towerOrb);
    // Make sure eyeIris is index 0 EDIT: nevermind
    tower = new WorldSegment(center, base, horizontal, vertical);
  }

  void initHouse()
  {
    // Shortened to shorten lines
    float groundHeight = 0;
    float ch = 0.2; // Ceiling height/thickness
    float h = 3; // Height
    float cy = h + ch / 2 + groundHeight; // Ceiling y
    float y = h / 2 + groundHeight; // Y position of walls

    Box roof1 = new Box(new PVector(-5, cy, -4), new PVector(9, ch, 1), Materials.white); // Main top
    Box roof2 = new Box(new PVector(-8, cy, -5.5), new PVector(3, ch, 2), Materials.white); // Main left
    Box roof3 = new Box(new PVector(-5, cy, -5.5), new PVector(3, ch, 2), Materials.glass); // Main glass
    Box roof4 = new Box(new PVector(-2, cy, -5.5), new PVector(3, ch, 2), Materials.white); // Main right
    Box roof5 = new Box(new PVector(-5, cy, -8), new PVector(9, ch, 3), Materials.white); // Main bottom
    Box roof6 = new Box(new PVector(-7, cy, -3.25), new PVector(4, ch, 0.5), Materials.white); // Entrance
    Box roof7 = new Box(new PVector(-2, cy, -3), new PVector(3, ch, 1), Materials.white); // Alcove

    // Counter clockwise order
    Box wall1 = new Box(new PVector(-8.5, y, -3.5), new PVector(1, h, 1), Materials.grey); // Left entry
    Box wall2 = new Box(new PVector(-9.25, y, -6.5), new PVector(0.5, h, 6), Materials.grey); // Left wall
    Box wall3 = new Box(new PVector(-7.5, y, -7), new PVector(3, h, 0.5), Materials.grey); // Left interior
    Box wall4_0 = new Box(new PVector(-5, y - h / 3, -9.25), new PVector(8, h / 3, 0.5), Materials.grey); // Bottom (bottom)
    Box wall4_1 = new Box(new PVector(-5, y, -9.25), new PVector(8, h / 3, 0.1), Materials.glass); // Bottom (window)
    Box wall4_2 = new Box(new PVector(-5, y + h / 3, -9.25), new PVector(8, h / 3, 0.5), Materials.grey); // Bottom (top)
    Box wall5 = new Box(new PVector(-4.5, y, -7.75), new PVector(0.25, h, 2.5), Materials.grey); // Bottom interior
    Box wall6 = new Box(new PVector(-0.75, y, -6.25), new PVector(0.5, h, 6.5), Materials.grey); // Right
    Box wall7 = new Box(new PVector(-2, y, -6.5), new PVector(2, h, 1), Materials.grey); // Right interior (bottom)
    Box wall8 = new Box(new PVector(-2.875, y, -5.5), new PVector(0.25, h, 1), Materials.grey); // Right interior (side)
    Box wall9 = new Box(new PVector(-2, y, -2.75), new PVector(3, h, 0.5), Materials.grey); // Top right
    Box wall10 = new Box(new PVector(-3.25, y, -3.5), new PVector(0.5, h, 1), Materials.grey); // Top connector
    Box wall11 = new Box(new PVector(-4.25, y, -3.75), new PVector(1.5, h, 0.5), Materials.grey); // Top middle
    Box wall12 = new Box(new PVector(-5.5, y, -3.5), new PVector(1, h, 1), Materials.grey); // Right entry

    float lh = 0.25; // Light height/thickness
    float ly = groundHeight + h - lh / 2; // Light y, at top corner of walls & ceiling

    Box light1 = new Box(new PVector(-8.75, ly, -6.5), new PVector(0.25, lh, 5), Materials.incandescent); // Left
    Box light2 = new Box(new PVector(-1.25, ly, -6), new PVector(0.25, lh, 6), Materials.incandescent); // Right

    house = new WorldSegment(roof1, roof2, roof3, roof4, roof5, roof6, roof7,
      wall1, wall2, wall3, wall4_0, wall4_1, wall4_2, wall5, wall6, wall7, wall8, wall9, wall10, wall11, wall12,
      light1, light2);
  }

  void initSpheres()
  {
    float height = 4;
    Box wall1 = new Box(new PVector(6, height / 2, 8), new PVector(2, height, 0.2), Materials.white);
    Box wall2 = new Box(new PVector(7, height / 2, 6), new PVector(3.5, height, 0.2), Materials.black);
    
    spheres = new WorldSegment(wall1, wall2);
  }
}
