#!/bin/bash

# These corresspond to the Network Numbers output by the Li parcellation; the corr matrices are 0-17 so the numbers are shifted there 

declare -A networks=(
  [Lateral_Visual]=2
  [Primary_Visual]=3
  [Dorsal_Motor]=4
  [Ventral_Motor]=5
  [Visual_Association]=6
  [Dorsal_Attention]=7
  [Cingulo_Opercular]=8
  [Salience]=9
  [Temporal_Lobe]=10
  [Orbitofrontal]=11
  [Precuneus_PCC_Posterior_DMN]=12
  [FPCN_B]=13
  [FPCN_A]=14
  [Lateral_Temporal]=15
  [Medial_Temporal]=16
  [DMN_Canonical]=17
  [DMN_dorsal]=18
  [Motor_hand]=19
)

# Example usage:
for key in "${!networks[@]}"; do
  echo "${key} -> ${networks[$key]}"
done

# Or lookup directly:
# echo "FPCN_A is ${networks[FPCN_A]}"
