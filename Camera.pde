class Camera
{
  PVector position;
  PVector rotation;
  float fov;
  float jitter; // Pixel jitter for anti aliasing

  Camera(PVector position, PVector rotation, float fov, float jitter)
  {
    this.position = position;
    this.rotation = rotation;
    this.fov = fov;
    this.jitter = jitter;
  }

  // Rotates around 2 axes
  void rotate(float x, float y)
  {
    rotation.y -= x;
    rotation.x -= y;
    rotation.x = constrain(rotation.x, -90, 90);
  }

  // Where we are looking
  PVector getForward()
  {
    return rotateVector(new PVector(0, 0, 1), rotation.x, rotation.y);
  }

  // Cha cha slide to the right
  PVector getRight()
  {
    return rotateVector(new PVector(1, 0, 0), 0, rotation.y);
  }

  // Not used, but it could be
  void move(float side, float forwards)
  {
    position.add(flatten(getForward()).normalize().mult(forwards));
    position.add(getRight().mult(side));
  }

  // Gets the ray at the specified pixel
  Ray getViewRay(int xPixel, int yPixel, int width, int height)
  {
    // No real science here, just guesses
    // Edit: It's good now (fov is actually accurate)

    float aspect = width / (float)height;

    // x and y coords from -1 to 1 (pixels are centered)
    float xNorm = (xPixel + 0.5) / (float)width * 2 - 1;
    float yNorm = 1 - (yPixel + 0.5) / (float)height * 2; // Flip image right way round

    // Half the width of a pixel in normalized coordinates (very small)
    float pxDistHX = 0.5f / width;
    float pxDistHY = 0.5f / height;

    // Jitter them within their pixel (before stretching)
    xNorm += random(-pxDistHX, pxDistHX) * jitter;
    yNorm += random(-pxDistHY, pxDistHY) * jitter;

    xNorm *= aspect; // Multiply is cheaper than divide
    //yNorm /= aspect;

    // https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html
    float fovFactor = tan(radians(fov / 2));
    xNorm *= fovFactor;
    yNorm *= fovFactor;

    //float virtualDistance = 90f / fov;
    //PVector virtualOffset = new PVector(xNorm, yNorm, virtualDistance);
    PVector virtualOffset = new PVector(xNorm, yNorm, 1);

    virtualOffset = rotateVector(virtualOffset, rotation.x, rotation.y);
    return new Ray(position, virtualOffset.normalize());
    
    // Old single axis rotation code (scuffed)
    //float roll = radians(rotation.z);
    //rotate(virtualOffset, 0, 0, pitch);
    //rotate(virtualOffset, yaw, 0, 0);
    //PVector vec2d = new PVector(xNorm, virtualDistance);
    //vec2d.rotate(radians(angle));
    //PVector virtualOffset = new PVector(vec2d.x, yNorm, vec2d.y);
  }
}
