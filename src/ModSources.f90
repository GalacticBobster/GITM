!  Copyright (C) 2002 Regents of the University of Michigan, portions used with permission 
!  For more information, see http://csem.engin.umich.edu/tools/swmf

module ModSources

  use ModSizeGitm
  use ModPlanet, only: nSpecies,nSpeciesTotal,nIons

  !\
  ! Sources for neutral temperature
  !/

  real, dimension(nLons, nLats, nAlts) :: &
       NOCooling, OCooling, ElectronHeating, &
       AuroralHeating, JouleHeating, IonPrecipHeating, &
       EddyCond,EddyCondAdia

  real, dimension(nLons, nLats, 0:nAlts+1) :: MoleConduction

! JMB: 07/13/2017.  Conduction must extend 0:nAlts+1
! for the 2nd order update and 2nd order boundary conditions
  real, dimension(nLons, nLats, 0:nAlts+1) :: &
       Conduction

  real, dimension(nLons, nLats) :: &
       JouleHeating2d, EuvHeating2d, HeatTransfer2d, RadiativeCooling2d
       
  real, allocatable :: EuvHeating(:,:,:,:)
  real, allocatable :: EuvHeating_bp(:,:,:,:)
  real, allocatable :: eEuvHeating(:,:,:,:)
  real, allocatable :: PhotoElectronHeating(:,:,:,:)
  real, allocatable :: RadCooling(:,:,:,:)
  real, allocatable :: RadCoolingRate(:,:,:,:)
  real, allocatable :: RadCoolingRate_untouched(:,:,:,:)
  
  real, allocatable :: RadCoolingErgs(:,:,:,:)
  real, allocatable :: EuvHeatingErgs(:,:,:,:)
  real, allocatable :: LowAtmosRadRate(:,:,:,:)
  real, allocatable :: UserHeatingRate(:,:,:,:)
  real, allocatable :: DissociationHeatingRate(:,:,:,:)

  real, allocatable :: QnirTOT(:,:,:,:)
  real, allocatable :: QnirLTE(:,:,:,:)
  real, allocatable :: CirLTE(:,:,:,:)
  real, allocatable :: GradientPressure(:,:,:,:)
  real, allocatable :: HorizontalAdvectionTemperature(:,:,:,:)
  real(kind=8), allocatable :: eHeatingp(:,:,:)
  real(kind=8), allocatable :: iHeatingp(:,:,:)
  real(kind=8), allocatable :: eHeatingm(:,:,:)
  real(kind=8), allocatable :: iHeatingm(:,:,:)
  real(kind=8), allocatable :: iHeating(:,:,:)
  real(kind=8), allocatable :: lame(:,:,:)
  real(kind=8), allocatable :: lami(:,:,:)

  

  real, dimension(nLons,nLats,nAlts,3) :: GWAccel = 0.0

  !BP
  real, dimension(40,11) :: qIR_table

  !\
  ! Reactions used in chemistry output
  ! i.e. in2p_e -->  n2+ + e
  !      ino_n  -->  no + n
  !/

  
  integer, parameter :: nReactions = 26
  real :: ChemicalHeatingSpecies(nLons, nLats, nAlts,nReactions)
  real :: ChemicalHeatingS(nReactions)
  real :: NeutralSourcesTotal(nAlts, nSpeciesTotal)
  real :: NeutralLossesTotal(nAlts, nSpeciesTotal)
  real, allocatable :: ISourcesTotal(:,:,:,:,:)
  real, allocatable :: ILossesTotal(:,:,:,:,:)

  integer, parameter ::    in2p_e = 1
  integer, parameter ::    io2p_e = 2
  integer, parameter ::    in2p_o = 3
  integer, parameter ::    inop_e = 4
  integer, parameter ::    inp_o2 = 5
  integer, parameter ::    ino_n  = 6
  integer, parameter ::    iop_o2 = 7
  integer, parameter ::    in_o2  = 8
  integer, parameter ::    io2p_n = 9
  integer, parameter ::    io2p_no= 10
  integer, parameter ::    io2p_n2= 11
  integer, parameter ::    in2p_o2= 12
  integer, parameter ::    inp_o  = 13
  integer, parameter ::    iop_n2 = 14
  integer, parameter ::    io1d_n2 = 15
  integer, parameter ::    io1d_o2 = 16
  integer, parameter ::    io1d_o  = 17
  integer, parameter ::    io1d_e  = 18
  integer, parameter ::    in2d_o2 = 19
  integer, parameter ::    iop2d_e = 20
  integer, parameter ::    in2d_o = 21
  integer, parameter ::    in2d_e = 22
  integer, parameter ::    iop2d_n2 =23
  integer, parameter ::    iop2p_e = 24
  integer, parameter ::    iop2p_o = 25
  integer, parameter ::    iop2p_n2 = 26




  !\
  ! Stuff for auroral energy deposition and ionization
  !/

  real, dimension(:), allocatable :: &
       ED_grid, ED_Energies, ED_Flux, ED_Ion, ED_Heating
  integer :: ED_N_Energies, ED_N_Alts
  real, dimension(nAlts) :: ED_Interpolation_Weight
  integer, dimension(nAlts) :: ED_Interpolation_Index

  real, allocatable :: AuroralIonRateS(:,:,:,:,:)
  real, allocatable :: AuroralHeatingRate(:,:,:,:)
  real, allocatable :: IonPrecipIonRateS(:,:,:,:,:)
  real, allocatable :: IonPrecipHeatingRate(:,:,:,:)
  real :: ChemicalHeatingRate(nLons, nLats, nAlts)
  real :: ChemicalHeatingRateIon(nLons, nLats, nAlts)
  real :: ChemicalHeatingRateEle(nLons, nLats, nAlts)

  !BP                                                                                         
  real, dimension(40,11) :: qIR_NLTE_table
  real, dimension(19,16) :: diurnalHeating, semiDiurnalHeating  

  real :: HorizontalTempSource(nLons, nLats, nAlts)

  real :: Diffusion(nLons, nLats, nAlts, nSpecies)
  real :: NeutralFriction(nLons, nLats, nAlts, nSpecies)
  real :: IonNeutralFriction(nLons, nLats, nAlts, nSpecies)

  real, allocatable :: KappaEddyDiffusion(:,:,:,:)

contains
  !=========================================================================
  subroutine init_mod_sources


    if(allocated(EuvHeating)) RETURN
    allocate(EuvHeating(nLons, nLats, nAlts,nBlocks))
    allocate(EuvHeating_bp(nLons,nLats,nAlts,nBlocks))
    allocate(eEuvHeating(nLons, nLats, nAlts,nBlocks))
    allocate(PhotoElectronHeating(nLons, nLats, nAlts,nBlocks))
    allocate(RadCooling(nLons, nLats, nAlts,nBlocks))
    allocate(RadCoolingRate(nLons, nLats, nAlts,nBlocks))
    allocate(RadCoolingRate_untouched(nLons, nLats, nAlts,nBlocks))
    allocate(RadCoolingErgs(nLons, nLats, nAlts,nBlocks))
    allocate(EuvHeatingErgs(nLons, nLats, nAlts,nBlocks))
    allocate(LowAtmosRadRate(nLons, nLats, nAlts,nBlocks))
    allocate(QnirTOT(nLons, nLats, nAlts,nBlocks))
    allocate(QnirLTE(nLons, nLats, nAlts,nBlocks))
    allocate(CirLTE(nLons, nLats, nAlts,nBlocks))
    allocate(UserHeatingRate(nLons, nLats, nAlts,nBlocks))
    allocate(ISourcesTotal(nLons,nLats,nAlts,nIons-1,nBlocks))
    allocate(ILossesTotal(nLons,nLats,nAlts,nIons-1,nBlocks))
    allocate(AuroralIonRateS(nLons,nLats,nAlts,nSpecies,nBlocks))
    allocate(AuroralHeatingRate(nLons,nLats,nAlts,nBlocks))
    allocate(IonPrecipIonRateS(nLons,nLats,nAlts,nSpecies,nBlocks))
    allocate(IonPrecipHeatingRate(nLons,nLats,nAlts,nBlocks))
    allocate(KappaEddyDiffusion(nLons,nLats,-1:nAlts+2,nBlocks))
    allocate(DissociationHeatingRate(nLons, nLats, nAlts,nBlocks))
    allocate(GradientPressure(nLons,nLats,nAlts,nBlocks))
    allocate(HorizontalAdvectionTemperature(nLons,nLats,nAlts,nBlocks))
    allocate(eHeatingp(0:nLons+1,0:nLats+1,0:nAlts+1))
    allocate(iHeatingp(0:nLons+1,0:nLats+1,0:nAlts+1))
    allocate(eHeatingm(0:nLons+1,0:nLats+1,0:nAlts+1))
    allocate(iHeatingm(0:nLons+1,0:nLats+1,0:nAlts+1))
    allocate(iHeating(0:nLons+1,0:nLats+1,0:nAlts+1))
    allocate(lame(0:nLons+1,0:nLats+1,0:nAlts+1))
    allocate(lami(0:nLons+1,0:nLats+1,0:nAlts+1))

    EuvHeating = 0.0
  end subroutine init_mod_sources
  !=========================================================================
  subroutine clean_mod_sources


    if(.not.allocated(EuvHeating)) RETURN
    deallocate(EuvHeating)
    deallocate(EuvHeating_bp)
    deallocate(eEuvHeating)
    deallocate(PhotoElectronHeating)
    deallocate(RadCooling)
    deallocate(RadCoolingRate)
    deallocate(RadCoolingRate_untouched)
    deallocate(RadCoolingErgs)
    deallocate(EuvHeatingErgs)
    deallocate(LowAtmosRadRate)
    deallocate(QnirTOT)
    deallocate(QnirLTE)
    deallocate(CirLTE)
    deallocate(UserHeatingRate)
    deallocate(ISourcesTotal)
    deallocate(ILossesTotal)
    deallocate(AuroralIonRateS)
    deallocate(AuroralHeatingRate)
    deallocate(IonPrecipIonRateS)
    deallocate(IonPrecipHeatingRate)
    deallocate(KappaEddyDiffusion)
    deallocate(DissociationHeatingRate)
    deallocate(GradientPressure)
    deallocate(HorizontalAdvectionTemperature)
  end subroutine clean_mod_sources
  !=========================================================================
end module ModSources
