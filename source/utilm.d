module utilm;

import vars : TWO_PI;

void fixAngleRad(float *angle)
{
	if      (*angle > TWO_PI) *angle %= TWO_PI;
	else if (*angle <   0) *angle += TWO_PI;
}
