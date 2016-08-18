! qmc_pi_lj_module.f90
! Energy and move routines for PIMC simulation, LJ potential
MODULE qmc_pi_lj_module

  USE, INTRINSIC :: iso_fortran_env, ONLY : output_unit, error_unit

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: n, p, r, lt, ne, gt
  PUBLIC :: initialize, finalize, energy_cl_1, energy_cl, energy_qu_1, energy_qu
  PUBLIC :: move

  INTEGER                                :: n ! number of atoms
  INTEGER                                :: p ! number of beads
  REAL,    DIMENSION(:,:,:), ALLOCATABLE :: r ! positions (3,n,p)

  INTEGER, PARAMETER :: lt = -1, ne = 0, gt = 1 ! j-range and l-range options

CONTAINS

  SUBROUTINE initialize
    ALLOCATE ( r(3,n,p) )
  END SUBROUTINE initialize

  SUBROUTINE finalize
    DEALLOCATE ( r )
  END SUBROUTINE finalize

  SUBROUTINE energy_cl ( sigma, r_cut, overlap, pot )
    REAL,    INTENT(in)  :: sigma, r_cut ! potential parameters
    LOGICAL, INTENT(out) :: overlap      ! shows if an overlap was detected
    REAL,    INTENT(out) :: pot          ! classical LJ potential 

    ! Calculates classical potential for whole system
    ! Includes a check for overlap (potential too high) to avoid overflow
    ! If overlap==.true., the value of pot should not be used
    ! It is assumed that r, sigma and r_cut are in units where box = 1
    ! Results are in LJ units where sigma = 1, epsilon = 1

    REAL    :: pot_i
    INTEGER :: i, k

    IF ( n /= SIZE(r,dim=2) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, n=', n, SIZE(r,dim=2)
       STOP 'Error in energy_cl'
    END IF
    IF ( p /= SIZE(r,dim=3) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, p=', p, SIZE(r,dim=3)
       STOP 'Error in energy_cl'
    END IF

    overlap = .FALSE.
    pot     = 0.0

    DO k = 1, p ! Loop over ring polymers
       DO i = 1, n - 1 ! Loop over atoms within polymer
          CALL energy_cl_1 ( r(:,i,k), i, k, gt, sigma, r_cut, overlap, pot_i )
          IF ( overlap ) EXIT ! jump out of loop
          pot  = pot + pot_i
       END DO ! End loop over atoms within polymer
    END DO ! End loop over ring polymers

  END SUBROUTINE energy_cl

  SUBROUTINE energy_cl_1 ( rik, i, k, j_range, sigma, r_cut, overlap, pot )

    REAL, DIMENSION(3), INTENT(in)  :: rik           ! coordinates of atom of interest
    INTEGER,            INTENT(in)  :: i, k, j_range ! index, polymer id, and partner index range
    REAL,               INTENT(in)  :: r_cut, sigma  ! LJ potential parameters
    LOGICAL,            INTENT(out) :: overlap       ! shows if an overlap was detected
    REAL,               INTENT(out) :: pot           ! potential

    ! Calculates LJ potential energy of atom in rik for given polymer k
    ! pot contains the result 
    ! with j/=i, j>i, or j<i depending on j_range
    ! Includes a check for overlap (potential too high) to avoid overflow
    ! If overlap==.true., the value of pot should not be used
    ! It is assumed that r, sigma and r_cut are in units where box = 1
    ! Results are in LJ units where sigma = 1, epsilon = 1

    INTEGER            :: j, j1, j2
    REAL               :: r_cut_sq, sigma_sq
    REAL               :: sr2, sr6, r_ik_jk_sq
    REAL, DIMENSION(3) :: r_ik_jk
    REAL, PARAMETER    :: sr2_overlap = 1.8 ! overlap threshold

    IF ( n /= SIZE(r,dim=2) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, n=', n, SIZE(r,dim=2)
       STOP 'Error in energy_cl_1'
    END IF
    IF ( p /= SIZE(r,dim=3) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, p=', p, SIZE(r,dim=3)
       STOP 'Error in energy_cl_1'
    END IF

    r_cut_sq = r_cut**2
    sigma_sq = sigma**2

    pot     = 0.0
    overlap = .FALSE.

    SELECT CASE ( j_range )
    CASE ( lt ) ! j < i
       j1 = 1
       j2 = i-1
    CASE ( gt ) ! j > i
       j1 = i+1
       j2 = n
    CASE ( ne ) ! j /= i
       j1 = 1
       j2 = n
    END SELECT

    DO j = j1, j2

       IF ( i == j ) CYCLE

       r_ik_jk(:) = rik(:) - r(:,j,k)
       r_ik_jk(:) = r_ik_jk(:) - ANINT ( r_ik_jk(:) ) ! periodic boundaries in box=1 units
       r_ik_jk_sq = SUM ( r_ik_jk**2 )

       IF ( r_ik_jk_sq < r_cut_sq ) THEN

          sr2 = sigma_sq / r_ik_jk_sq ! now dimensionless

          IF ( sr2 > sr2_overlap ) THEN
             overlap = .TRUE.
             EXIT ! jump out of loop
          END IF

          sr6 = sr2**3
          pot = pot + sr6**2 - sr6

       END IF

    END DO
    pot = 4.0 * pot        ! factor of 4*epsilon
    pot = pot / real ( p ) ! classical potentials are weaker by a factor p

  END SUBROUTINE energy_cl_1

  SUBROUTINE energy_qu ( k_spring, sigma, pot )
    REAL, INTENT(in)  :: k_spring, sigma ! potential parameters
    REAL, INTENT(out) :: pot             ! quantum spring potential 

    ! Calculates quantum spring potential for whole system
    ! It is assumed that r, sigma are in units where box = 1
    ! Results are in LJ units where sigma = 1, epsilon = 1

    REAL    :: pot_i
    INTEGER :: i, k

    IF ( n /= SIZE(r,dim=2) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, n=', n, SIZE(r,dim=2)
       STOP 'Error in energy_qu'
    END IF
    IF ( p /= SIZE(r,dim=3) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, p=', p, SIZE(r,dim=3)
       STOP 'Error in energy_qu'
    END IF

    pot = 0.0

    DO k = 1, p ! Loop over ring polymers
       DO i = 1, n ! Loop over atoms within polymer
          CALL energy_qu_1 ( r(:,i,k), i, k, gt, k_spring, sigma, pot_i )
          pot  = pot + pot_i
       END DO ! End loop over atoms within polymer
    END DO ! End loop over ring polymers

  END SUBROUTINE energy_qu

  SUBROUTINE energy_qu_1 ( rik, i, k, l_range, k_spring, sigma, pot )

    REAL, DIMENSION(3), INTENT(in)  :: rik             ! coordinates of atom of interest
    INTEGER,            INTENT(in)  :: i, k, l_range   ! index, polymer id, and partner index range
    REAL,               INTENT(in)  :: k_spring, sigma ! potential parameters
    REAL,               INTENT(out) :: pot             ! potential

    ! Calculates quantum spring potential energy of atom in ri for given polymer k
    ! pot contains the result 
    ! with l=k-1, l=k+1, or both depending on l_range
    ! It is assumed that r, sigma are in units where box = 1
    ! Results are in LJ units where sigma = 1, epsilon = 1

    INTEGER            :: l
    REAL               :: sigma_sq
    REAL               :: r_ik_il_sq
    REAL, DIMENSION(3) :: r_ik_il

    IF ( n /= SIZE(r,dim=2) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, n=', n, SIZE(r,dim=2)
       STOP 'Error in energy_qu_1'
    END IF
    IF ( p /= SIZE(r,dim=3) ) THEN ! should never happen
       WRITE ( unit=error_unit, fmt='(a,2i15)' ) 'Array bounds error for r, p=', p, SIZE(r,dim=3)
       STOP 'Error in energy_qu_1'
    END IF

    sigma_sq = sigma**2
    pot      = 0.0

    IF (  l_range == lt .OR. l_range == ne ) THEN ! look at l = k-1
       l = k-1
       IF ( l < 1 ) l = p
       r_ik_il(:) = rik(:) - r(:,i,l)
       r_ik_il(:) = r_ik_il(:) - ANINT ( r_ik_il(:) ) ! periodic boundaries in box=1 units
       r_ik_il_sq = SUM ( r_ik_il**2 ) / sigma_sq     ! squared distance in LJ units
       pot = pot + 0.5 * k_spring * r_ik_il_sq
    END IF

    IF (  l_range == gt .OR. l_range == ne ) THEN ! look at l = k+1
       l = k+1
       IF ( l > p ) l = 1
       r_ik_il(:) = rik(:) - r(:,i,l)
       r_ik_il(:) = r_ik_il(:) - ANINT ( r_ik_il(:) ) ! periodic boundaries in box=1 units
       r_ik_il_sq = SUM ( r_ik_il**2 ) / sigma_sq     ! squared distance in LJ units
       pot = pot + 0.5 * k_spring * r_ik_il_sq
    END IF

  END SUBROUTINE energy_qu_1

  SUBROUTINE move ( i, k, rik )
    INTEGER,               INTENT(in) :: i, k
    REAL,    DIMENSION(3), INTENT(in) :: rik

    r(:,i,k) = rik

  END SUBROUTINE move

END MODULE qmc_pi_lj_module
