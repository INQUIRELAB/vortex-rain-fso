function [newDirection, newPhase, newPosition, newTime, lost] = scatterPhoton( ...
        photon_position, photon_direction, Phaseshift, time_to_hit, ...
        n_water, n_air, lambda, raindrop_center, r)
%SCATTERPHOTON  Geometrical-optics scattering of one ray by a spherical drop.
%
%   RECONSTRUCTED ROUTINE.  The original scatterPhoton.m was not archived with
%   the simulation code and its author is unreachable.  This version was
%   rebuilt from (a) the call signature in simulate_GO_with_model.m (line 94)
%   and the way the five outputs are consumed (lines 94-104), and (b) the
%   standard geometrical-optics treatment of refraction by a water sphere.
%   It was then checked against the intact R = 100 mm/h, model 10 segment data.
%
%   I/O CONTRACT (fixed by the caller, recovered exactly):
%     photon_position  : 1x3, the foot point the caller already computed (the
%                        point on the incoming ray closest to the drop centre).
%     photon_direction : 1x3 unit propagation direction of the incoming ray.
%     Phaseshift       : scalar, accumulated rain phase (available, not required).
%     time_to_hit      : scalar, accumulated time     (available, not required).
%     n_water          : complex refractive index of water (Re: refraction,
%                        Im: absorption); 1.318 + 9.8625e-5i at 1550 nm.
%     n_air            : refractive index of air (1).
%     lambda           : wavelength in nm.
%     raindrop_center  : 1x3 centre of the drop being hit.
%     r                : drop radius in metres.
%   Returns:
%     newDirection : 1x3 outgoing direction (caller re-normalises).
%     newPhase     : INCREMENTAL phase, added by the caller to Phaseshift and Phase.
%     newPosition  : 1x3 exit point on the drop surface.
%     newTime      : INCREMENTAL transit time, added by the caller via abs(newTime).
%     lost         : logical; true if the event removes the photon.  This is the
%                    5th output, currently ignored by the caller; provided for
%                    completeness / future use.
%
%   PHYSICS (default).  Primary transmitted ray, p = 1: the ray refracts in at
%   the near surface (vector Snell), crosses the chord, and refracts out at the
%   far surface.  Geometric deviation is 2*(theta_i - theta_t).  newPhase is the
%   excess optical path (Re(n_water) - 1) * L through the drop.  Absorption from
%   Im(n_water) over the in-drop path L can be applied as a survival weight
%   exp(-2*k0*Im(n_water)*L); see the commented block at the end.
%
%   VALIDATION AND CAVEAT.  Driven by a rain field rebuilt from define_constants
%   (N drops placed uniformly in the l x l x z box) and the archived initial
%   photons, this kernel reproduces the monotonic attenuation TREND and the
%   vortex-ring degradation seen in the data, but it attenuates FASTER than the
%   archived R = 100 survivor curve (roughly 2x-10x with distance):
%
%        z (m)    this kernel    archived (R=100, model 10)
%         100       ~35%              75%
%         300       ~ 4%              35%
%         500       ~0.6%             5.6%
%
%   At size parameter x = 2*pi*r/lambda ~ 2.0e3 the true scattering is dominated
%   by the forward-diffraction lobe, which a refracted-ray-only model omits; the
%   original kernel evidently retained more forward-going light.  The single
%   constant FORWARD_FRACTION below routes that fraction of encounters into the
%   near-forward channel; calibrate it against the intact R = 100 data if
%   quantitative agreement with the archived results is required.  The default
%   FORWARD_FRACTION = 0 gives the transparent, parameter-free refracted ray.
%
%   This file makes the published pipeline runnable and is physically defensible
%   as a geometrical-optics kernel.  It is NOT guaranteed to reproduce the
%   paper's exact numbers; note its reconstructed status wherever results from a
%   fresh run are reported.

    FORWARD_FRACTION = 0.0;   % 0 = pure refracted ray (default, deterministic).
                              % Set in (0,1) and calibrate against the archived
                              % R = 100 data to soften attenuation toward the
                              % original (Babinet forward lobe at large x).

    c   = 299792458;                         % speed of light (m/s)
    k0  = 2*pi/(lambda*1e-9);                % vacuum wavenumber (1/m)
    nw  = real(n_water);
    d   = photon_direction(:).' / norm(photon_direction);
    C   = raindrop_center(:).';
    P   = photon_position(:).';

    % --- forward-diffraction channel (large size parameter) --------------
    if FORWARD_FRACTION > 0 && rand < FORWARD_FRACTION
        Lf = 2*sqrt(max(r^2 - norm(C - P)^2, 0));   % chord length
        newDirection = d;                            % continues forward
        newPosition  = P;
        newPhase     = k0*(nw - n_air)*Lf;
        newTime      = nw*Lf/c;
        lost         = false;
        return;
    end

    % --- geometric entry point on the sphere -----------------------------
    b  = norm(C - P);                        % impact parameter (< r)
    h  = sqrt(max(r^2 - b^2, 0));            % half-chord
    A  = P - h*d;                            % entry point on the surface
    nA = (A - C)/r;                          % outward normal at entry

    t_in = refract(d, nA, n_air/nw);         % air -> water

    f  = A - C;
    L  = -2*dot(f, t_in);                    % geometric path inside the drop
    B  = A + L*t_in;                         % exit point on the surface
    nB = (B - C)/r;                          % outward normal at exit

    t_out = refract(t_in, -nB, nw/n_air);    % water -> air (incident side -nB)

    newDirection = t_out / norm(t_out);
    newPosition  = B;
    newPhase     = k0*(nw - n_air)*L;        % excess optical phase from the drop
    newTime      = nw*L/c;                   % transit delay through the water
    lost         = false;

    % --- optional absorption from Im(n_water) ----------------------------
    % alpha = 2*k0*imag(n_water)*L;          % intensity attenuation exponent
    % lost  = rand > exp(-alpha);            % stochastic removal if modelling it
end

function t = refract(d, n, eta)
%REFRACT  Vector Snell refraction.  n is the unit normal on the incident side,
%         eta = n1/n2.  Falls back to specular reflection on total internal
%         reflection.
    ci = -dot(n, d);
    s2 = eta^2*(1 - ci^2);
    if s2 > 1
        t = d - 2*dot(d, n)*n;               % total internal reflection
    else
        t = eta*d + (eta*ci - sqrt(1 - s2))*n;
    end
    t = t/norm(t);
end
