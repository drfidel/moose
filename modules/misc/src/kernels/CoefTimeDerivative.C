//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "CoefTimeDerivative.h"

template <>
InputParameters
validParams<CoefTimeDerivative>()
{
  InputParameters params = validParams<TimeDerivative>();
  params.addParam<Real>("Coefficient", 1, "The coefficient for the time derivative kernel");
  return params;
}

CoefTimeDerivative::CoefTimeDerivative(const InputParameters & parameters)
  : TimeDerivative(parameters), _coef(getParam<Real>("Coefficient"))
{
}

Real
CoefTimeDerivative::computeQpResidual()
{
  // We're reusing the TimeDerivative Kernel's residual
  // so that we don't have to recode that.
  return _coef * TimeDerivative::computeQpResidual();
}

Real
CoefTimeDerivative::computeQpJacobian()
{
  return _coef * TimeDerivative::computeQpJacobian();
}
