
// Welcome to the shed of random math functions


int sign(float f) // Returns the sign of F
{
  if (f < 0) return -1;
  if (f > 0) return 1;
  return 0;
}

float lerp_float(float a, float b, float t) // Linear interpolation
{
  return (1 - t) * a + t * b;
}

PVector invert(PVector p) // Inverts a vector (I hate PVector semantics, I loooove unity Vector3s so much more now)
{
  return new PVector(0, 0, 0).sub(p);
}

PVector reflect(PVector ray, PVector normal) // Reflects a vector across a normal
{
  float dot = ray.dot(normal);
  return ray.copy().sub(normal.copy().mult(dot * 2));
}

float saturate(float value) // clamp(value, 0, 1);
{
  return constrain(value, 0f, 1f);
}

PVector flatten(PVector value) // Returns a vector with the y component set to 0
{
  return new PVector(value.x, 0, value.z);
}

float sqrMag(PVector v) // Square magnitude of a vector (cheaper than v.mag(), avoids a sqrt)
{
  return v.x * v.x + v.y * v.y + v.z * v.z;
}

float sqrDist(PVector a, PVector b) // Square distance (cheap)
{
  return sqrMag(a.copy().sub(b));
}

/*
static int rand()
 {
 rndSeed = rndSeed*1103515245 + 12345;
 return (int)(rndSeed/65536) % 32768;
 }
 */


int rndSeed;

// Fast random
// I'm sure these are horribly cursed but they are faster
float rand()
{
  // For the life of my I can't find where I took this function from, but it isn't mine
  rndSeed = rndSeed*1103515245 + 12345;
  return abs((rndSeed/65536) % 32768) / (float)Short.MAX_VALUE;
}

float randn1to1()
{
  rndSeed = rndSeed*1103515245 + 12345;
  return ((rndSeed/65536) % 32768) / (float)Short.MAX_VALUE;
}

PVector randSphere()
{
  // Fast! (-er)
  return new PVector(randn1to1(), randn1to1(), randn1to1());
}

// Rotates a vector by pitch and yaw
PVector rotateVector(PVector vector, float pitch, float yaw)
{
  pitch = radians(pitch);
  yaw = radians(yaw);
  vector = vector.copy();
  rotate(vector, 0, 0, pitch); // They have to be passed in in a weird way though... eh
  rotate(vector, yaw, 0, 0);
  return vector;
}

// https://stackoverflow.com/questions/34050929/3d-point-rotation-algorithm
void rotate(PVector dir, float pitch, float yaw, float roll) {
  float cosa = cos(yaw);
  float sina = sin(yaw);

  float cosb = cos(pitch);
  float sinb = sin(pitch);

  float cosc = cos(roll);
  float sinc = sin(roll);

  float Axx = cosa*cosb;
  float Axy = cosa*sinb*sinc - sina*cosc;
  float Axz = cosa*sinb*cosc + sina*sinc;

  float Ayx = sina*cosb;
  float Ayy = sina*sinb*sinc + cosa*cosc;
  float Ayz = sina*sinb*cosc - cosa*sinc;

  float Azx = -sinb;
  float Azy = cosb*sinc;
  float Azz = cosb*cosc;

  float px = dir.x;
  float py = dir.y;
  float pz = dir.z;

  dir.x = Axx*px + Axy*py + Axz*pz;
  dir.y = Ayx*px + Ayy*py + Ayz*pz;
  dir.z = Azx*px + Azy*py + Azz*pz;
}

boolean vecEqual(PVector a, PVector b) // Are these vectors equal?
{
  return a.x == b.x && a.y == b.y && a.z == b.z;
}


// Data class to store the result (no 'out' variables)
class QuadraticResult
{
  float t0, t1;
  boolean solved;

  QuadraticResult(float t0, float t1, boolean solved)
  {
    this.t0 = t0;
    this.t1 = t1;
    this.solved = solved;
  }
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
QuadraticResult SolveQuadratic(float a, float b, float c)
{
  // I love quadratic formula <3
  float disc = b * b - 4 * a * c;
  if (disc < 0) return new QuadraticResult(0, 0, false);
  else if (disc == 0)
  {
    float t = -0.5 * b / a;
    return new QuadraticResult(t, t, true);
  } else
  {
    float quadraticStuff = b > 0 ?
      -0.5 * (b + sqrt(disc)) :
      -0.5 * (b - sqrt(disc));

    float t0 = quadraticStuff / a;
    float t1 = c / quadraticStuff;

    if (t0 > t1)
    {
      float temp = t1;
      t1 = t0;
      t0 = temp;
    }

    return new QuadraticResult(t0, t1, true);
  }
}


// All of these functions below are ripped from Space Invaders
void drawBitmap(int bitmap, int numBits, float x, float y, float boxSize)
{
  // Draw whatever bits are set in the bitmap
  // Graphical settings (fill() etc) should be set beforehand
  
  for (int i = 0; i < numBits; i++)
  {
    // Draw a rect if the bit is set
    if (isBitSet(bitmap, i))
    {
      // Reverse i because bitmaps are backwards
      rect(x + (numBits - i) * boxSize, y, boxSize, boxSize);
    }
  }
}

int numberOfBitsSet(int mask)
{
  int count = 0;

  for (int i = 0; i < 32; i++)
  {
    // Just count through all the bits, seeing how many are set (1)
    if (isBitSet(mask, i))
      count++;
  }

  return count;
}

// Returns true if the bit at bitIndex in mask is 1
boolean isBitSet(int mask, int bitIndex)
{
  //i.e 10011 checking if index 1 is set
  // 10011
  // 00010 <- 1 << 1
  // &
  // 00010 > 0 therefore set

  return (mask & (1 << bitIndex)) > 0; // May not work for 32nd bit?
  // Two's compliment shenanigans or smth
  // Space invaders rows are 11 anyways
}

// Returns mask with the given bit set (1)
int setBit(int mask, int bitIndexToSet)
{
  // OR with the mask of bitIndexToSet
  return mask | (1 << bitIndexToSet);
}

// Returns mask with the given bit cleared (0)
int clearBit(int mask, int bitIndexToClear)
{
  // AND with the inverse mask of bitIndexToClear
  return mask & ~(1 << bitIndexToClear);
}

// Returns mask with the given bit flipped
int toggleBit(int mask, int bitIndex)
{
  if (isBitSet(mask, bitIndex))
    return clearBit(mask, bitIndex);
  return setBit(mask, bitIndex);
}
