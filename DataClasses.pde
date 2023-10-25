
/*

 This file is lots of classes that are (relatively) small and mainly just hold data
 
 */




// ========================================== RAY ================================== //
class Ray
{
  PVector pos;
  PVector dir;

  // More efficient box intersection per
  //https://www.researchgate.net/publication/220494140_An_Efficient_and_Robust_Ray-Box_Intersection_Algorithm
  PVector invDir;
  int[] sign;

  Ray(PVector position, PVector direction)
  {
    this.pos = position.copy();
    this.dir = direction.copy().normalize();
  }

  // These funky guys are only used for box intersection,
  //  so this code is only called when boxes are being calculated
  void calculateBoxMembers()
  {
    if (invDir != null)
      return;

    invDir = new PVector(1f / dir.x, 1f / dir.y, 1f / dir.z);
    sign = new int[3];
    sign[0] = invDir.x < 0 ? 1 : 0;
    sign[1] = invDir.y < 0 ? 1 : 0;
    sign[2] = invDir.z < 0 ? 1 : 0;
  }

  // Cast it into the world and see if we get anything
  Hit cast(World world)
  {
    float closestDistance = Float.POSITIVE_INFINITY; // How close the closest object is
    Hit hit = null;
    for (Object o : world.objects)
    {
      if (o == null)
        continue; // Skip null objects
      Hit hitToCheck = o.intersect(this);
      if (hitToCheck != null && hitToCheck.intersects)
      {
        // If we intersect and are closest, set it as such
        float distance = pos.dist(hitToCheck.point);
        if (distance < closestDistance) {
          closestDistance = distance;
          hit = hitToCheck;
        }
      }
    }

    // Return the closest hit (may be null)
    return hit;
  }
}



// ========================================== MATERIAL ================================== //
class Material
{
  // Just a data class
  Colour colour;
  float smoothness;
  float glassShininess;
  float emissionPower;
  Colour emissionColour;
  //float metallic;

  //Material(Colour colour, float specular)
  Material(Colour colour, float smoothness)//, float metallic)
  {
    this(colour, smoothness, 0.5);
  }

  Material(Colour colour, float smoothness, float glassShininess)
  {
    this.colour = colour;
    this.smoothness = smoothness;
    this.glassShininess = glassShininess;
    emissionColour = new Colour(0, 0, 0);
    emissionPower = 0;
  }

  Material setEmission(float emissionPower, Colour emissionColour)
  {
    this.emissionPower = emissionPower;
    this.emissionColour = emissionColour;
    return this;
  }

  // HDR colour (or something like that)
  Colour getEmission()
  {
    return emissionColour.copy().mult(emissionPower);
  }
}




// ========================================== IMAGE ================================== //
class Image
{
  // Simply stores a bunch of colours
  // (and has some helper functions)
  int width, height;
  private Colour[] buffer;

  Image(int width, int height)
  {
    this.width = width;
    this.height = height;
    buffer = new Colour[width * height];
    clear(new Colour(0, 0, 0));
  }

  // Initializes all pixels to this colour
  void clear(Colour colour)
  {
    for (int i = 0; i < width * height; i++)
    {
      buffer[i] = colour.copy();
    }
  }

  void set(int x, int y, Colour colour)
  {
    buffer[y * width + x] = colour;
  }

  Colour get(int x, int y)
  {
    return buffer[y * width + x];
  }

  // Get by index instead of x & y
  Colour getIndex(int index)
  {
    return buffer[index];
  }

  void setIndex(int index, Colour colour)
  {
    buffer[index] = colour;
  }
}



// ========================================== IMAGE METADATA ================================== //
class ImageMetadata
{
  // Stores position and angle for images (or for any purpose)
  PVector position;
  PVector angle;

  ImageMetadata(PVector position, PVector angle)
  {
    this.position = position;
    this.angle = angle;
  }

  ImageMetadata()
  {
    this.position = new PVector();
    this.angle = new PVector();
  }

  // Returns true if this metadata is close enough to another metadata to be considered equal
  // (for rendering accumulation purposes)
  boolean matches(ImageMetadata other)
  {
    // Position can be close enough
    float dist = 0.1 * 0.1;
    return sqrDist(position, other.position) < dist && vecEqual(angle, other.angle);
    //return vecEqual(position, other.position) && vecEqual(angle, other.angle);
  }

  void set(PVector position, PVector angle)
  {
    this.position.set(position);
    this.angle.set(angle);
  }
}








// ========================================== HIT ================================== //
class Hit
{
  /*
  final Object object;
   final PVector point;
   final PVector normal;
   final float thickness;
   final boolean intersects;
   */

  // Stores information about a ray intersection with an object
  Object object; // The hit object
  PVector point; // Where we hit it
  PVector normal; // The normal of the hit
  float thickness; // How thick the hit was
  float distance; // How far away the hit was
  boolean intersects; // Do we even actually intersect? (used for null/empty returns)

  Hit(Object object, PVector point, PVector normal, float thickness, float distance, boolean intersects)
  {
    this.object = object;
    this.point = point.copy();
    this.normal = normal.copy().normalize();
    this.thickness = Float.isNaN(thickness) ? 0 : thickness;
    this.distance = distance;
    this.intersects = intersects;
  }

  Hit()
  {
    // Empty constructor for hits that don't hit
    this(null, new PVector(0, 0, 0), new PVector(0, 0, 0), 0, 0, false);
  }
}




// ========================================== COLOUR ================================== //
class Colour
{
  // Stores a colour as floats rather than a bitmask to allow HDR and to not make my life a pain
  private float r, g, b, a;

  Colour(float r, float g, float b)
  {
    this(r, g, b, 1);
  }

  Colour(float r, float g, float b, float a)
  {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;

    //clampValues();
  }

  // Just a bunch of helper methods, all are pretty self explanatory
  void set(float r, float g, float b, float a)
  {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;

    //clampValues();
  }

  void set(Colour other)
  {
    this.r = other.r;
    this.g = other.g;
    this.b = other.b;
    this.a = other.a;
  }

  Colour add(Colour colour)
  {
    r += colour.r;
    g += colour.g;
    b += colour.b;
    a += colour.a;
    //clampValues();
    return this;
  }

  Colour mult(float value)
  {
    r *= value;
    g *= value;
    b *= value;
    //clampValues();
    return this;
  }

  Colour mult(Colour colour)
  {
    r *= colour.r;
    g *= colour.g;
    b *= colour.b;
    //a *= colour.a;
    //clampValues();
    return this;
  }

  Colour copy()
  {
    return new Colour(r, g, b, a);
  }

  Colour clampValues()
  {
    r = constrain(r, 0f, 1f);
    g = constrain(g, 0f, 1f);
    b = constrain(b, 0f, 1f);
    a = constrain(a, 0f, 1f);
    return this;
  }
}

// These are outside of the Colour class (global functions)

// Averages an array of colours
Colour average(Colour... colours)
{
  float r = 0, g = 0, b = 0, a = 0;
  int count = 0;
  for (Colour c : colours)
  {
    if (c == null)
      continue; // Skip null colours
    count++;
    r += c.r;
    g += c.g;
    b += c.b;
    a += c.a;
  }

  if (count == 0)
    return new Colour(0, 0, 0);

  r /= count;
  g /= count;
  b /= count;
  a /= count;
  return new Colour(r, g, b, a);
}

// Linearly interpolates between two colours (just lerps their components)
Colour lerp(Colour a, Colour b, float t)
{
  return new Colour(lerp_float(a.r, b.r, t), lerp_float(a.g, b.g, t), lerp_float(a.b, b.b, t), lerp_float(a.a, b.a, t));
}



// ========================================== RENDER PROFILE ================================== //
class RenderProfile
{
  // Stores rendering settings
  int numBufferedFrames; // How many total frames to buffer
  int samples_moving; // How many samples per pixel to calculate while moving
  int samples_accumulate; // How many samples per pixel to calculate while accumulating
  int maxBounces_moving; // How many times a ray can bounce while moving
  int maxBounces_accumulate; // How many times a ray can bounce while accumulating
  int fps; // Max target FPS
  int renderScale; // Downsize multiplier (larger is less pixels)

  RenderProfile(int numBufferedFrames, int samples_moving, int samples_accumulate, int maxBounces_moving, int maxBounces_accumulate, int fps, int renderScale)
  {
    this.numBufferedFrames = numBufferedFrames;
    this.samples_moving = samples_moving;
    this.samples_accumulate = samples_accumulate;
    this.maxBounces_moving = maxBounces_moving;
    this.maxBounces_accumulate = maxBounces_accumulate;
    this.fps = fps;
    this.renderScale = renderScale;
  }
}

// Old render profiles (between progress 9 and 11 zips I cleaned it up)
/*
class RenderProfile
 {
 int numBufferedFrames; // How many total frames to buffer
 float samplePercentCenter; // Percent 0-1 of pixels to sample near the center of the screen
 float samplePercentEdges; // Percent 0-1 of pixels to sample near the edges of the screen
 int samples; // How many samples per pixel to calculate
 int maxBounces; // How many times a ray can bounce
 int fps; // Max target FPS
 float fuzziness; // How much to blur the result
 int renderScale; // Downsize multiplier (larger is less pixels)
 int changingBuffer; // How many frames to render whil the camera is moving
 
 RenderProfile(int numBufferedFrames, float samplePercentCenter, float samplePercentEdges, int samples, int maxBounces, int fps, float fuzziness, int renderScale, int changingBuffer)
 {
 this.numBufferedFrames = numBufferedFrames;
 this.samplePercentCenter = samplePercentCenter;
 this.samplePercentEdges = samplePercentEdges;
 this.samples = samples;
 this.maxBounces = maxBounces;
 this.fps = fps;
 this.fuzziness = fuzziness;
 this.renderScale = renderScale;
 this.changingBuffer = changingBuffer;
 }
 }
 */
