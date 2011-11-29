class ArcaboucoController
  Instances : []

  register: ( ControllerObject, Application ) ->
    instanceClass = new ControllerObject()
    if instanceClass.bootstrap or instanceClass.getRoutes
      ControllerObject = instanceClass
    ControllerObject.bootstrap( Application ) if ControllerObject.bootstrap
    @Instances.push( ControllerObject )-1

  unregister: ( controllerIndex ) ->
    false

  get: ( controllerIndex ) ->
    if @Instances[ controllerIndex ] then @Instances[ controllerIndex ] else null

module.exports = ArcaboucoController
