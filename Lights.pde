
// This file was used in earlier versions
// Now only DirectionalLight is used, and only to hold data

class Light
{
  Colour colour;
  float intensity;
  
  PVector getDirectionFrom(PVector point)
  {
    return null;
  }
  
  float getIntensityAtPoint(PVector point)
  {
    return 0;
  }
}

class PointLight extends Light
{
  PVector position;
  float falloffDistance;

  PointLight(PVector position, Colour colour, float intensity, float falloffDistance)
  {
    this.position = position.copy();
    this.colour = colour;
    this.intensity = intensity;
    this.falloffDistance = falloffDistance;
  }
  
  PVector getDirectionFrom(PVector point)
  {
    return position.copy().sub(point).normalize();
  }
  
  float getIntensityAtPoint(PVector point)
  {
    float dist = point.dist(position);
    // Inverse square
    return (1f / dist * dist) * falloffDistance;
  }
}

class DirectionalLight extends Light
{
  PVector direction;

  DirectionalLight(PVector direction, Colour colour, float intensity)
  {
    this.direction = direction.copy().normalize();
    this.colour = colour;
    this.intensity = intensity;
  }
  
  PVector getDirectionFrom(PVector point)
  {
    return invert(direction).normalize();
  }
  
  float getIntensityAtPoint(PVector point)
  {
    return intensity;
  }
}
