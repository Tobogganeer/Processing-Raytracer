class Renderer
{
  // The top and bottom colours of the skybox
  // I yoinked them from an RGB colour picker so just divide by 255
  Colour skyboxBottom = new Colour(200 / 255f, 220 / 255f, 230 / 255f);
  Colour skyboxTop = new Colour(57 / 255f, 147 / 255f, 237 / 255f);

  boolean renderSkybox = true;

  Renderer() // We need no constructor here
  {
    // Maybe let people specify the skybox here? They can just edit the values anyways
  }

  // The big kahoonas (or something)
  void render(Image renderTarget, Camera camera, World world, int samples, int maxBounces) //, float samplePercentCenter, float samplePercentEdges)
  {
    samples = max(samples, 1); // Clamp them samples)
    Colour[] colourBuf = new Colour[samples]; // To avoid reallocations
    int maxDepth = maxBounces + 1;

    for (int x = 0; x < renderTarget.width; x++)
    {
      for (int y = 0; y < renderTarget.height; y++)
      {
        // Sample percent is always 1 now, keeping it as a historical artifact
        /*
        float samplePercent = samplePercentCenter;
         
         // Bias sample towards center
         if (samplePercentCenter != samplePercentEdges)
         {
         // -1 to 1
         float xNorm = (x / (float)renderTarget.width) * 2 - 1;
         float yNorm = (y / (float)renderTarget.height) * 2 - 1;
         float t = (xNorm * xNorm + yNorm * yNorm) / 1.414;
         //t = pow(t, 0.3);
         samplePercent = lerp(samplePercentCenter, samplePercentEdges, t);
         }
         
         //if (random(0f, 1f) > samplePercent)
         if (samplePercent < 1.0 && rand() > samplePercent)
         continue; // Lower sample count
         */

        if (samples == 1)
        {
          // No loop or array needed
          Colour c = calculateLighting(x, y, renderTarget, camera, world, maxDepth);
          renderTarget.set(x, y, c);
        } else
        {
          for (int i = 0; i < samples; i++)
          {
            colourBuf[i] = calculateLighting(x, y, renderTarget, camera, world, maxDepth);
          }

          renderTarget.set(x, y, average(colourBuf).clampValues());
        }
      }
    }
  }

  Colour calculateLighting(int x, int y, Image renderTarget, Camera camera, World world, int maxDepth)
  {
    // Converts the X and Y into a ray and passes its work to another function (lazy)
    Ray ray = camera.getViewRay(x, y, renderTarget.width, renderTarget.height);

    return calculateLighting(ray, camera, world, maxDepth);
  }

  Colour getSkyboxColour(Ray ray, World world)
  {
    float y = (ray.dir.y + 1) / 2f; // Convert the Y into 0 to 1 range
    Colour skyColour = lerp(skyboxBottom, skyboxTop, y); // The colour at this height
    float sunDot = saturate(ray.dir.dot(invert(world.sun.direction.normalize()))); // How much this ray is pointing to the sun
    float largeDisc = 1.0 * pow(sunDot, 4) * sun.intensity; // The big wide influence
    float smallDisc = 3.0 * pow(sunDot, 50) * sun.intensity; // The actual 'sun' itself
    return skyColour.add(world.sun.colour.copy().mult(largeDisc + smallDisc)); // Return the colour back
  }

  // Thanks to these two sources for influencing basically all of this
  // https://raytracing.github.io/books/RayTracingInOneWeekend.html#metal/mirroredlightreflection
  // Emission: https://www.youtube.com/watch?v=AbVfW4X01a0
  Colour calculateLighting(Ray ray, Camera cam, World world, int depth)
  {
    Colour light = new Colour(0, 0, 0);
    Colour throughput = new Colour(1, 1, 1);

    for (int i = 0; i < depth; i++)
    {
      Hit hit = ray.cast(world);

      // Did we not hit any objects? Then just skybox
      if (hit == null || !hit.intersects)
      {
        if (renderSkybox)
          light.add(getSkyboxColour(ray, world).mult(throughput));
        break;
      }

      light.add(hit.object.material.getEmission().mult(lerp(throughput, new Colour(1, 1, 1), 0.5))); // Make the albedo affect it a bit
      throughput.mult(hit.object.material.colour);
      //light.add(hit.object.material.getEmission());

      // Scatter the ray and recast it
      ray = scatterRay(ray, hit);

      // Old stuff
      /*
      if (scattered != null)
       {
       EmissiveColour scatter = calculateLighting(scattered, cam, world, depth - 1);
       Colour c = hit.object.material.colour.copy().mult(scatter.colour);
       return new EmissiveColour(c, scatter.emission + hit.object.material.emission);
       }
       return new EmissiveColour(new Colour(0, 0, 0), 0);
       */
    }

    return light;
  }

  Ray scatterRay(Ray rayIn, Hit hit)
  {
    // Scatter the ray depending on the material of the object we hit
    // (most of it is bs'ed randomly)

    //PVector scatterDir = hit.normal.copy().add(PVector.random3D().normalize());
    PVector scatterDir = hit.normal.copy().add(randSphere().normalize()); // Fast random saves ~1.2fps in interactive
    if (sqrMag(scatterDir) < 0.01)
      scatterDir = hit.normal.copy();
    PVector opaque = scatterDir.copy();
    PVector reflectDir = null;

    if (hit.object.material.smoothness > 0.0 || hit.object.material.colour.a < 1.0)
      reflectDir = reflect(rayIn.dir, hit.normal); // Only calculate the reflected direction if we need it

    if (hit.object.material.smoothness > 0.0) // Reflect it a bit
      opaque = PVector.lerp(scatterDir, reflectDir, hit.object.material.smoothness);

    PVector finalDirection;

    // Don't calculate transparency for opaque objects
    if (hit.object.material.colour.a < 1.0)
    {
      // Not anywhere near physically accurate glass, just random guesses
      float grazing = 1 - max(-rayIn.dir.dot(hit.normal), 0); // Closer to 0 when perpendicular

      //PVector refract = invert(hit.normal).add(PVector.random3D().normalize());
      PVector refract = invert(hit.normal).add(randSphere().normalize()); // Pass it a bit through the object
      PVector transmittedDir = PVector.lerp(invert(hit.normal), rayIn.dir, saturate(hit.thickness)); // How much it should go straight through vs inverted inwards
      PVector transparent = PVector.lerp(transmittedDir, reflectDir, hit.object.material.glassShininess * grazing);
      transparent = PVector.lerp(refract, transparent, hit.object.material.smoothness);
      finalDirection = PVector.lerp(transparent, opaque, hit.object.material.colour.a);
    } else
    {
      finalDirection = opaque;
    }

    finalDirection.normalize();

    // Push out of object a bit
    Ray scattered = new Ray(hit.point.copy().add(finalDirection.copy().mult(0.001)), finalDirection);
    return scattered;
  }


  // EDIT: WHAT AM I DOING!!! THIS IS RAYTRACING, NOT RASTERIZING!!!

  // Old code that was using rasterization formulas and other rubbish
  // https://www.gamedeveloper.com/programming/implementing-lighting-models-with-hlsl
  /*
  Colour calculateLighting(Light light, Ray incoming, Hit hit, Camera cam, World world)
   {
   PVector lightDir = light.getDirectionFrom(hit.point);
   float fac = constrain(hit.normal.dot(lightDir), 0, 1) * light.intensity;
   Colour diffuse = hit.object.material.colour.copy().mult(fac);
   
   //PVector reflected = hit.normal.copy().mult(2 * fac).sub(lightDir).normalize();
   PVector reflected = lightDir.copy().add(incoming.dir).normalize();
   float specular = pow(constrain(hit.normal.dot(reflected), 0, 1), 8) * hit.object.material.specular;
   Colour specColour = new Colour(specular, specular, specular);
   
   Colour litColour = diffuse.add(specColour).mult(light.colour);
   litColour.mult(light.getIntensityAtPoint(hit.point));
   return litColour;
   }
   */
}
