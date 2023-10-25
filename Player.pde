class Player
{
  // Just holds a bunch of info and moves around
  PVector position;
  PVector velocity;
  float angle;
  Camera cam;
  float eyeHeight;
  
  // Height and radius are irrelevant for now, didn't have time for collision
  //float height;
  //float radius;
  
  //float acceleration = 8;

  Player(PVector position, Camera cam, float eyeHeight)//, float height, float radius)
  {
    this.position = position;
    velocity = new PVector(0, 0);
    this.angle = 0;
    this.cam = cam;
    this.eyeHeight = eyeHeight;
    //this.height = height;
    //this.radius = radius;
  }

  void move(float speed, boolean w, boolean a, boolean s, boolean d)
  {
    // Store input in a vector
    PVector desired = new PVector(0, 0);
    if (w) desired.y += 1;
    if (a) desired.x -= 1;
    if (s) desired.y -= 1;
    if (d) desired.x += 1;
    desired.normalize();
    desired.mult(speed);
    
    // Convert to world space
    desired = cam.getRight().mult(desired.x).add(flatten(cam.getForward()).normalize().mult(desired.y));
    
    // Velocity was weird and unsavoury with the weird FPS fluctuations,
    //  so just use our desired velocity directly
    velocity = desired;
    //velocity = PVector.lerp(velocity, desired, dt * acceleration);

    position.add(velocity.copy().mult(dt)); // Physics 101
  }

  void rotate(float angle)
  {
    this.angle += angle; // Most advanced function on earth
  }

  void tick()
  {
    // Move the camera to match us
    cam.position.set(position.x, position.y + eyeHeight, position.z);
    cam.rotation.y = angle;
  }

  Hit raycast(float maxDistance, World world)
  {
    // Just cast a ray out and return it if it hits
    Hit hit = cam.getViewRay(100, 100, 200, 200).cast(world);
    if (hit != null && hit.distance < maxDistance)
      return hit;
    return new Hit();
  }
}
