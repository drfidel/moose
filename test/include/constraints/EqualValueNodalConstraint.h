/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*           (c) 2010 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#ifndef EQUALVALUENODALCONSTRAINT_H
#define EQUALVALUENODALCONSTRAINT_H

#include "NodalConstraint.h"

class EqualValueNodalConstraint;

template<>
InputParameters validParams<EqualValueNodalConstraint>();

class EqualValueNodalConstraint : public NodalConstraint
{
public:
  EqualValueNodalConstraint(const InputParameters & parameters);
  virtual ~EqualValueNodalConstraint();

protected:
  virtual Real computeQpResidual(Moose::ConstraintType type, NumericVector<Number> & residual);
  virtual Real computeQpJacobian(Moose::ConstraintJacobianType type, SparseMatrix<Number> & jacobian);

  Real _penalty;
};

#endif /* EQUALVALUENODALCONSTRAINT_H */
