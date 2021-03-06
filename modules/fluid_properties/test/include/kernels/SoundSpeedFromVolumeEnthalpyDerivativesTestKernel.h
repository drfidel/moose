//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#ifndef SOUNDSPEEDFROMVOLUMEENTHALPYDERIVATIVESTESTKERNEL_H
#define SOUNDSPEEDFROMVOLUMEENTHALPYDERIVATIVESTESTKERNEL_H

#include "FluidPropertyDerivativesTestKernel.h"

class SoundSpeedFromVolumeEnthalpyDerivativesTestKernel;

template <>
InputParameters validParams<SoundSpeedFromVolumeEnthalpyDerivativesTestKernel>();

/**
 * Tests derivatives of sound speed from specific volume and specific enthalpy
 */
class SoundSpeedFromVolumeEnthalpyDerivativesTestKernel : public FluidPropertyDerivativesTestKernel
{
public:
  SoundSpeedFromVolumeEnthalpyDerivativesTestKernel(const InputParameters & parameters);
  virtual ~SoundSpeedFromVolumeEnthalpyDerivativesTestKernel();

protected:
  virtual Real computeQpResidual() override;
  virtual Real computeQpOffDiagJacobian(unsigned int jvar) override;

  /// specific volume
  const VariableValue & _v;
  /// specific enthalpy
  const VariableValue & _h;

  /// specific volume coupled variable index
  const unsigned int _v_index;
  /// specific enthalpy coupled variable index
  const unsigned int _h_index;
};

#endif /* SOUNDSPEEDFROMVOLUMEENTHALPYDERIVATIVESTESTKERNEL_H */
