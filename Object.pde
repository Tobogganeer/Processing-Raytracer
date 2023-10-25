// Represents an object in the world
class Object
{
  PVector position;
  Material material;

  Object(PVector position)
  {
    this(position, null);
  }

  Object(PVector position, Material material)
  {
    this.position = position.copy();
    this.material = material;
  }

  Hit intersect(Ray ray)
  {
    // An object cannot exist on it's own (abstract)
    return null;
  }
}

class Sphere extends Object
{
  float radius;

  Sphere(PVector position, float radius, Material material)
  {
    super(position, material);
    this.radius = radius;
  }

  // https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
  Hit intersect(Ray ray)
  {
    // Ray begins inside sphere
    if (ray.pos.dist(position) < radius)
      return new Hit();


    PVector L = ray.pos.copy().sub(position);
    float a = ray.dir.dot(ray.dir);
    float b = 2 * ray.dir.dot(L);
    float c = L.dot(L) - radius * radius;
    QuadraticResult qr = SolveQuadratic(a, b, c);
    if (!qr.solved)
      return new Hit();

    float t0 = qr.t0, t1 = qr.t1;
    if (qr.t0 > qr.t1) // Flip front and back hit
    {
      t1 = qr.t0;
      t0 = qr.t1;
    }

    if (t0 < 0)
    {
      t0 = t1;
      if (t0 < 0) // Behind shape
        return new Hit();
    }

    PVector frontHit = ray.pos.copy().add(ray.dir.copy().mult(t0));
    PVector rearHit = ray.pos.copy().add(ray.dir.copy().mult(t1));
    PVector normal = frontHit.copy().sub(position);
    return new Hit(this, frontHit, normal, frontHit.dist(rearHit), frontHit.dist(ray.pos), true);
  }

  // https://iquilezles.org/articles/intersectors/
  PVector sphIntersect( PVector ro, PVector rd, PVector ce, float ra )
  {
    PVector oc = ro.copy().sub(ce);
    float b = oc.dot(rd);
    PVector qc = oc.copy().sub(rd.copy().mult(b));
    float h = ra*ra - qc.dot(qc);
    if ( h<0.0 ) return new PVector(-1.0, -1.0); // no intersection
    h = sqrt( h );
    return new PVector( -b-h, -b+h );
  }
}

class Plane extends Object
{
  PVector normal;

  Plane(PVector normal, Material material)
  {
    super(new PVector(0, 0, 0), material);
    this.normal = normal.copy().normalize();
  }

  // https://www.cl.cam.ac.uk/teaching/1999/AGraphHCI/SMAG/node2.html#SECTION00023500000000000000
  Hit intersect(Ray ray)
  {
    float d = -normal.x * position.x - normal.y * position.y - normal.z * position.z;
    float distance = (-ray.pos.dot(normal) - d) / ray.dir.dot(normal);
    if (distance < 0)
      return new Hit();

    PVector point = ray.pos.copy().add(ray.dir.copy().mult(distance));
    return new Hit(this, point, normal, 0.01, point.dist(ray.pos), true);
  }
}

class Disc extends Object
{
  PVector normal;
  float radius;

  Disc(PVector position, PVector normal, float radius, Material material)
  {
    super(position, material);
    this.normal = normal.copy().normalize();
    this.radius = radius;
  }

  // https://www.cl.cam.ac.uk/teaching/1999/AGraphHCI/SMAG/node2.html#SECTION00023500000000000000
  Hit intersect(Ray ray)
  {
    float t = discIntersect(ray.pos, ray.dir, position, normal, radius);
    if (t < 0) return new Hit();

    PVector point = ray.pos.copy().add(ray.dir.copy().mult(t));
    return new Hit(this, point, normal, 0.01, point.dist(ray.pos), true);
  }

  // https://iquilezles.org/articles/intersectors/
  // disk center c, normal n, radius r
  float discIntersect(PVector ro, PVector rd, PVector c, PVector n, float r )
  {
    PVector o = ro.copy().sub(c);
    float t = -n.dot(o) / rd.dot(n);
    PVector q = o.copy().add(rd.copy().mult(t));
    return (q.dot(q) <  r * r) ? t : -1.0;
  }
}


class Box extends Object
{
  PVector size;
  PVector[] bounds;

  PVector extents;

  Box(PVector position, PVector size, Material material)
  {
    super(position, material);
    this.size = size.copy();
    extents = size.copy().div(2f);
    bounds = new PVector[2];
    PVector extents = size.copy().div(2);
    bounds[0] = position.copy().sub(extents); // Min
    bounds[1] = position.copy().add(extents); // Max
  }


  Hit intersect(Ray ray)
  {
    // Set up sign[] and invDir
    ray.calculateBoxMembers();

    return boxIntersection(ray, position, extents);
  }

  // https://iquilezles.org/articles/boxfunctions/
  Hit boxIntersection(Ray ray, PVector boxPos, PVector boxExtents)
  {
    PVector ro = ray.pos.copy().sub(boxPos); // Center around origin
    PVector rd = ray.dir;
    PVector m = ray.invDir.copy();
    PVector rad = boxExtents;

    PVector n = vecMult(m, ro);
    PVector k = vecMult(vecAbs(m), rad);
    PVector t1 = invert(n).copy().sub(k);
    PVector t2 = invert(n).copy().add(k);

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );

    if ( tN>tF || tF<0.0) return new Hit(); // no intersection

    if (tN < 0) return new Hit(); // Inside box

    PVector t1yzx = new PVector(t1.y, t1.z, t1.x);
    PVector t1zxy = new PVector(t1.z, t1.x, t1.y);
    PVector normal = vecMult(vecMult(invert(vecSign(rd)), vecStep(t1yzx, t1)), vecStep(t1zxy, t1));

    PVector point = ray.pos.copy().add(ray.dir.copy().mult(tN));
    return new Hit(this, point, normal, abs(tF - tN), point.dist(ray.pos), true);
  }

  // Self-explanatory functions on vectors (I just looked up the HLSL functions and ported them)

  // Note: Modifies the vector, doesn't copy it
  PVector vecAbs(PVector v)
  {
    v.x = abs(v.x);
    v.y = abs(v.y);
    v.z = abs(v.z);
    return v;
  }

  PVector vecMult(PVector a, PVector b)
  {
    return new PVector(a.x * b.x, a.y * b.y, a.z * b.z);
  }

  PVector vecSign(PVector vec)
  {
    return new PVector(sign(vec.x), sign(vec.y), sign(vec.z));
  }

  /*
  boolean contains(PVector min, PVector max, PVector p)
   {
   return p.x > min.x &&
   }
   */

  PVector vecStep(PVector a, PVector b)
  {
    return new PVector(step(a.x, b.x), step(a.y, b.y), step(a.z, b.z));
  }

  int step(float y, float x)
  {
    return x >= y ? 1 : 0;
  }

  //https://iquilezles.org/articles/boxfunctions/
}
