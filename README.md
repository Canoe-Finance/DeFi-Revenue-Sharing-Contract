# MetaDex-Contract

## Swap Contract Preparation

Because different projects will charge a handling fee for the amount paid by the user, the contract is basically divided into two major points:
- Different projects will charge different amount of handling fee ratio
- The swap of the number of tokens after the user deducts the handling fee

The contract uploads the fee ratio of the principal charged by different projects on the corresponding interface, such as: a project => 20%, b project => 30%, when the user performs swap, the user will be charged after the corresponding fee is charged. The payment amount of the handling fee is swapped.
Other functions are divided into: the already connected project party receives the handling fee, project party management, etc.

