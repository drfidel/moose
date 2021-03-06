//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "MooseTestProblem.h"

template <>
InputParameters
validParams<MooseTestProblem>()
{
  InputParameters params = validParams<FEProblem>();
  return params;
}

MooseTestProblem::MooseTestProblem(const InputParameters & params) : FEProblem(params)
{
  _console << "Hello, I am your FEProblemBase-derived class and my name is '" << this->name() << "'"
           << std::endl;
}

MooseTestProblem::~MooseTestProblem() { _console << "Goodbye!" << std::endl; }
