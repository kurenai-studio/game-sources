const MOBILE_REGEX =
  /Android|Blackberry|IEMobile|Opera Mini|Windows Phone|iPad|iPhone|iPod|webOS/i;

export const isMobile = MOBILE_REGEX.test(navigator.userAgent);
