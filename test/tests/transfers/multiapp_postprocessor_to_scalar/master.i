[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 10
  ny = 10
[]

[Variables]
  [./u]
  [../]
[]

[Kernels]
  [./diff]
    type = CoefDiffusion
    variable = u
    coef = 0.01
  [../]
  [./td]
    type = TimeDerivative
    variable = u
  [../]
[]

[BCs]
  [./left]
    type = DirichletBC
    variable = u
    boundary = left
    value = 0
  [../]
  [./right]
    type = DirichletBC
    variable = u
    boundary = right
    value = 1
  [../]
[]

[Postprocessors]
  [./average]
    type = ElementAverageValue
    variable = u
  [../]
[]

[Executioner]
  type = Transient
  num_steps = 5

  # Preconditioned JFNK (default)
  solve_type = 'PJFNK'

  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
[]

[Outputs]
  output_initial = true
  exodus = true
  [./console]
    type = Console
    perf_log = true
    linear_residuals = true
  [../]
[]

[MultiApps]
  [./pp_sub]
    app_type = MooseTestApp
    positions = '0.5 0.5 0 0.7 0.7 0'
    execute_on = timestep_end
    type = TransientMultiApp
    input_files = sub.i
  [../]
[]

[Transfers]
  [./pp_transfer]
    type = MultiAppPostprocessorToAuxScalarTransfer
    direction = to_multiapp
    multi_app = pp_sub
    from_postprocessor = average
    to_aux_scalar = from_master_app
  [../]
[]
