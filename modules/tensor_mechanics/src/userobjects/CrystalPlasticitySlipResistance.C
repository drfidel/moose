//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "CrystalPlasticitySlipResistance.h"

template <>
InputParameters
validParams<CrystalPlasticitySlipResistance>()
{
  InputParameters params = validParams<CrystalPlasticityUOBase>();
  params.addClassDescription("Crystal plasticity slip resistance base class.  Override the virtual "
                             "functions in your class");
  return params;
}

CrystalPlasticitySlipResistance::CrystalPlasticitySlipResistance(const InputParameters & parameters)
  : CrystalPlasticityUOBase(parameters)
{
}
