//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "NodalExtremeValue.h"

#include <algorithm>
#include <limits>

template <>
InputParameters
validParams<NodalExtremeValue>()
{
  // Define the min/max enumeration
  MooseEnum type_options("max=0 min=1", "max");

  // Define the parameters
  InputParameters params = validParams<NodalVariablePostprocessor>();
  params.addParam<MooseEnum>("value_type",
                             type_options,
                             "Type of extreme value to return. 'max' "
                             "returns the maximum value. 'min' returns "
                             "the minimum value.");
  return params;
}

NodalExtremeValue::NodalExtremeValue(const InputParameters & parameters)
  : NodalVariablePostprocessor(parameters),
    _type((ExtremeType)(int)parameters.get<MooseEnum>("value_type")),
    _value(_type == 0 ? -std::numeric_limits<Real>::max() : std::numeric_limits<Real>::max())
{
}

void
NodalExtremeValue::initialize()
{
  switch (_type)
  {
    case MAX:
      _value = -std::numeric_limits<Real>::max(); // start w/ the min
      break;

    case MIN:
      _value = std::numeric_limits<Real>::max(); // start w/ the max
      break;
  }
}

void
NodalExtremeValue::execute()
{
  switch (_type)
  {
    case MAX:
      _value = std::max(_value, _u[_qp]);
      break;

    case MIN:
      _value = std::min(_value, _u[_qp]);
      break;
  }
}

Real
NodalExtremeValue::getValue()
{
  switch (_type)
  {
    case MAX:
      gatherMax(_value);
      break;
    case MIN:
      gatherMin(_value);
      break;
  }

  return _value;
}

void
NodalExtremeValue::threadJoin(const UserObject & y)
{
  const NodalExtremeValue & pps = static_cast<const NodalExtremeValue &>(y);

  switch (_type)
  {
    case MAX:
      _value = std::max(_value, pps._value);
      break;
    case MIN:
      _value = std::min(_value, pps._value);
      break;
  }
}
