//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "SetupMeshAction.h"
#include "MooseApp.h"
#include "MooseMesh.h"
#include "FEProblem.h"
#include "ActionWarehouse.h"
#include "Factory.h"

template <>
InputParameters
validParams<SetupMeshAction>()
{
  InputParameters params = validParams<MooseObjectAction>();
  params.set<std::string>("type") = "FileMesh";

  params.addParam<bool>("second_order",
                        false,
                        "Converts a first order mesh to a second order "
                        "mesh.  Note: This is NOT needed if you are reading "
                        "an actual first order mesh.");

  params.addParam<std::vector<SubdomainID>>("block_id", "IDs of the block id/name pairs");
  params.addParam<std::vector<SubdomainName>>(
      "block_name", "Names of the block id/name pairs (must correspond with \"block_id\"");

  params.addParam<std::vector<BoundaryID>>("boundary_id", "IDs of the boundary id/name pairs");
  params.addParam<std::vector<BoundaryName>>(
      "boundary_name", "Names of the boundary id/name pairs (must correspond with \"boundary_id\"");

  params.addParam<bool>("construct_side_list_from_node_list",
                        false,
                        "If true, construct side lists from the nodesets in the mesh (i.e. if "
                        "every node on a give side is in a nodeset then add that side to a "
                        "sideset");

  params.addParam<std::vector<std::string>>(
      "displacements",
      "The variables corresponding to the x y z displacements of the mesh.  If "
      "this is provided then the displacements will be taken into account during "
      "the computation.");
  params.addParam<std::vector<BoundaryName>>("ghosted_boundaries",
                                             "Boundaries to be ghosted if using Nemesis");
  params.addParam<std::vector<Real>>("ghosted_boundaries_inflation",
                                     "If you are using ghosted boundaries you will want to set "
                                     "this value to a vector of amounts to inflate the bounding "
                                     "boxes by.  ie if you are running a 3D problem you might set "
                                     "it to '0.2 0.1 0.4'");

  params.addParam<unsigned int>(
      "uniform_refine", 0, "Specify the level of uniform refinement applied to the initial mesh");
  params.addParam<bool>("skip_partitioning",
                        false,
                        "If true the mesh won't be partitioned. This may cause large load "
                        "imbalanced but is currently required if you "
                        "have a simulation containing uniform refinement, adaptivity and stateful "
                        "material properties");

  // groups
  params.addParamNamesToGroup("displacements ghosted_boundaries ghosted_boundaries_inflation",
                              "Advanced");
  params.addParamNamesToGroup("second_order construct_side_list_from_node_list skip_partitioning",
                              "Advanced");
  params.addParamNamesToGroup("block_id block_name boundary_id boundary_name", "Add Names");

  return params;
}

SetupMeshAction::SetupMeshAction(InputParameters params) : MooseObjectAction(params) {}

void
SetupMeshAction::setupMesh(MooseMesh * mesh)
{
  std::vector<BoundaryName> ghosted_boundaries =
      getParam<std::vector<BoundaryName>>("ghosted_boundaries");

  for (const auto & bnd_name : ghosted_boundaries)
    mesh->addGhostedBoundary(mesh->getBoundaryID(bnd_name));

  if (isParamValid("ghosted_boundaries_inflation"))
  {
    std::vector<Real> ghosted_boundaries_inflation =
        getParam<std::vector<Real>>("ghosted_boundaries_inflation");
    mesh->setGhostedBoundaryInflation(ghosted_boundaries_inflation);
  }

  mesh->ghostGhostedBoundaries();

  if (getParam<bool>("second_order"))
    mesh->getMesh().all_second_order(true);

#ifdef LIBMESH_ENABLE_AMR
  unsigned int level = getParam<unsigned int>("uniform_refine");

  // Did they specify extra refinement levels on the command-line?
  level += _app.getParam<unsigned int>("refinements");

  mesh->setUniformRefineLevel(level);
#endif // LIBMESH_ENABLE_AMR

  // Add entity names to the mesh
  if (_pars.isParamValid("block_id") && _pars.isParamValid("block_name"))
  {
    std::vector<SubdomainID> ids = getParam<std::vector<SubdomainID>>("block_id");
    std::vector<SubdomainName> names = getParam<std::vector<SubdomainName>>("block_name");
    std::set<SubdomainName> seen_it;

    if (ids.size() != names.size())
      mooseError("You must supply the same number of block ids and names parameters");

    for (unsigned int i = 0; i < ids.size(); ++i)
    {
      if (seen_it.find(names[i]) != seen_it.end())
        mooseError("The following dynamic block name is not unique: " + names[i]);
      seen_it.insert(names[i]);
      mesh->setSubdomainName(ids[i], names[i]);
    }
  }
  if (_pars.isParamValid("boundary_id") && _pars.isParamValid("boundary_name"))
  {
    std::vector<BoundaryID> ids = getParam<std::vector<BoundaryID>>("boundary_id");
    std::vector<BoundaryName> names = getParam<std::vector<BoundaryName>>("boundary_name");
    std::set<SubdomainName> seen_it;

    if (ids.size() != names.size())
      mooseError("You must supply the same number of boundary ids and names parameters");

    for (unsigned int i = 0; i < ids.size(); ++i)
    {
      if (seen_it.find(names[i]) != seen_it.end())
        mooseError("The following dynamic boundary name is not unique: " + names[i]);
      mesh->setBoundaryName(ids[i], names[i]);
      seen_it.insert(names[i]);
    }
  }

  if (getParam<bool>("construct_side_list_from_node_list"))
    mesh->getMesh().get_boundary_info().build_side_list_from_node_list();

  // Here we can override the partitioning for special cases
  if (getParam<bool>("skip_partitioning"))
    mesh->getMesh().skip_partitioning(getParam<bool>("skip_partitioning"));
}

void
SetupMeshAction::act()
{
  // Create the mesh object and tell it to build itself
  if (_current_task == "setup_mesh")
  {
    _mesh = _factory.create<MooseMesh>(_type, "mesh", _moose_object_pars);
    if (isParamValid("displacements"))
      _displaced_mesh = _factory.create<MooseMesh>(_type, "displaced_mesh", _moose_object_pars);
  }
  else if (_current_task == "init_mesh")
  {
    _mesh->init();

    if (isParamValid("displacements"))
    {
      // Initialize the displaced mesh
      _displaced_mesh->init();

      std::vector<std::string> displacements = getParam<std::vector<std::string>>("displacements");
      if (displacements.size() < _displaced_mesh->dimension())
        mooseError(
            "Number of displacements must be greater than or equal to the dimension of the mesh!");
    }

    setupMesh(_mesh.get());

    if (_displaced_mesh)
      setupMesh(_displaced_mesh.get());
  }
}
