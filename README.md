This project regrorp all other sub-project that compose the Goldorak robots

It's fast deploy environment.

It's Actually compose of 
 . goldobot_ihm - the ihm that connect to the robot to visualize and initalize it
 . goldo_strat : the main strategic maker
 . goldo_broker_cpp
 . goldo_GR_SW4STM32 - manage the smt32 card
 . Palmi_robot - is the litle robot project, that was meant to move from flower to flower
 . ELEC - la partie Electrique

docs - regroup the litle readme or structure details meant for the lifetime of the project

Each subproject is  managed as submodule, so they are independent and you work and push on each one as before.
This repo allow to manage logic (deployment, compilation, etc..) for all of them at the same time
It also help manage create "release version" compilable and functionnal
(for example before refactoring a lot of code that impact multiple project, and may break the project for a long time
you push a commit on this repo holding the current sha / branch of each repo to save an instance of all repo that you know is compilable)
