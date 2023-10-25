class World
{
  // Basically just a list of objects (for now)
  ArrayList<Object> objects;
  //ArrayList<Light> lights;
  DirectionalLight sun;

  World(DirectionalLight sun)
  {
    this.sun = sun;
    objects = new ArrayList<Object>();
    //lights = new ArrayList<Light>();
  }

  void add(Object object)
  {
    if (object != null)
      objects.add(object);
  }

  /*
  void add(Light light)
   {
   lights.add(light);
   }
   */

  void remove(Object object)
  {
    if (object != null)
      objects.remove(object);
  }

  void load(WorldSegment segment)
  {
    for (Object o : segment.objects)
      add(o);
  }

  void unload(WorldSegment segment)
  {
    for (Object o : segment.objects)
      remove(o);
  }

  /*
  void remove(Light light)
   {
   lights.remove(light);
   }
   */

  void tick()
  {
    
  }
}

class WorldSegment
{
  // Just stores a list of objects (for organization and spatial partitioning)
  ArrayList<Object> objects = new ArrayList<Object>();

  WorldSegment(Object... objects)
  {
    for (Object o : objects)
      this.objects.add(o);
  }

  WorldSegment()
  {
  }

  void add(Object object)
  {
    objects.add(object);
  }

  void remove(Object object)
  {
    objects.remove(object);
  }
}
