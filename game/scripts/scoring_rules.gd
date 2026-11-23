extends RefCounted
## Balance only. Match validation and permanent progress retain their owners.
const OPERATOR_BASE := 100
const STREAK_MULTIPLIERS := [1.0, 1.05, 1.10, 1.15, 1.20]
const MAX_STREAK_MULTIPLIER := 1.20
const X_BASE := 20
const X_GROUP_BONUS := 5
const COMPLETION_BONUS := 500
const TIME_THRESHOLDS := [0.75, 1.0, 1.5, 2.0]
const TIME_BONUSES := [500, 350, 200, 100]
const QUALITY_MULTIPLIERS := [1.0, 1.15, 1.30]
const SEASON_GEAR_RATIO := 0.70
const GEARS_PER_LEVEL := 3

static func operator_points(streak: int) -> int:
    var multiplier: float = STREAK_MULTIPLIERS[clampi(streak - 1, 0, STREAK_MULTIPLIERS.size() - 1)]
    return roundi(OPERATOR_BASE * minf(multiplier, MAX_STREAK_MULTIPLIER))

static func x_points(count: int) -> int:
    return X_BASE * count + X_GROUP_BONUS * count * (count - 1) if count > 0 else 0

static func time_points(elapsed_sec: float, reference_sec: float) -> int:
    if reference_sec <= 0 or not is_finite(reference_sec):
        return 0
    for i in range(TIME_THRESHOLDS.size()):
        if elapsed_sec <= reference_sec * TIME_THRESHOLDS[i]:
            return TIME_BONUSES[i]
    return 0

static func quality_multiplier(gears: int) -> float:
    return QUALITY_MULTIPLIERS[clampi(gears - 1, 0, QUALITY_MULTIPLIERS.size() - 1)]
