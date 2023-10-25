
// A file to hold some common values and functions

RenderProfiles RenderProfiles = new RenderProfiles(); // Global accessor

class RenderProfiles
{
  // Render profiles (with list of what the arguments are)
  // Buffer Frames, Samples (moving), Samples (accumulate), Max Bounces (moving), Max Bounces (accumulate), FPS, Fuzziness, Render Scale
  RenderProfile interactive = new RenderProfile(32, 3, 6, 2, 4, 30, 4);
  RenderProfile low =         new RenderProfile(32, 4, 8, 3, 5, 15, 3);
  RenderProfile high =        new RenderProfile(32, 8, 32, 04, 8, 04, 2);
  RenderProfile ultra =       new RenderProfile(32, 96, 96, 10, 10, 01, 1);

  // Old render profiles
  // Buffer Frames, Sample Percent (center), Sample Percent (edges), Samples, Max Bounces, FPS, Fuzziness, Render Scale, Changing Buffer
  /*
  RenderProfile interactive = new RenderProfile(32, .3, .3, 04, 2, 30, 0.67, 3, 1);
   RenderProfile low =         new RenderProfile(06, 1.0, 0.3, 04, 3, 15, 0.40, 2, 2);
   RenderProfile high =        new RenderProfile(16, 1.0, 0.8, 32, 7, 04, 0.40, 2, 2);
   RenderProfile ultra =       new RenderProfile(24, 1.0, 1.0, 96, 10, 01, 0.00, 1, 1);
   */
}

Materials Materials = new Materials(); // Global accessor

class Materials
{
  // Not all of these are used
  // Colour colour, float smoothness, (optional) float glassShininess
  Material white = new Material(new Colour(0.9, 0.9, 0.9), 0.3);
  Material grey = new Material(new Colour(0.5, 0.5, 0.5), 0.3);
  Material black = new Material(new Colour(0.1, 0.1, 0.1), 0.3);
  Material metal = new Material(new Colour(0.9, 0.9, 0.9), 0.9);
  Material glass = new Material(new Colour(0.8, 0.8, 1.0, 0.2), 0.95, 0.5);
  Material foggyGlass = new Material(new Colour(0.8, 0.8, 1.0, 0.3), 0.75, 0.65);
  Material glow = new Material(new Colour(1.0, 0.75, 0.3), 0.0).setEmission(3, new Colour(1.0, 0.8, 0.5));
  Material grass = new Material(new Colour(0.2, 0.7, 0.3), 0.1);
  Material incandescent = new Material(new Colour(1.0, 0.91, 0.67), 0.0).setEmission(6, new Colour(1.0, 0.91, 0.67));
  Material towerOrb = new Material(new Colour(1.0, 0.1, 0.1), 0.5).setEmission(5, new Colour(1.0, 0.1, 0.1));
}
