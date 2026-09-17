# Duct Modeling and Heating Discrepancy: Resolved Interpretation

## Executive summary

The expanded `baseline_nd_ducts` experiment now provides the missing controlled comparison. It includes two additional variants with an **unheated-basement foundation**:

- Ducts in the unheated basement, 30% leakage, R-6 insulation.
- Ducts in living space, 0% leakage, uninsulated.

This resolves the main confounding issue. With the foundation held unheated, moving ducts from the unheated basement to living space reduces total electricity from **102.856 to 88.086 MBtu** and removes the separate **27.109 MBtu heating duct component load**. The duct-location effect is therefore large and credible.

The results support these conclusions:

1. Ducts in heated basements and living spaces have nearly identical performance for this building.
2. Ducts in an unheated basement create a substantial heating penalty, even when conditioned floor area is unchanged.
3. The unheated-basement foundation itself also changes the building thermal boundary, so the heated-basement-to-unheated-basement comparison combines foundation and duct effects.
4. The new same-foundation comparison isolates duct location and shows that ducts in the living space avoid the unheated duct-zone penalty.
5. Duct quality matters within an unheated basement: R-6 insulation reduces the duct penalty, while high leakage and no insulation produce the largest load.
6. Since conditioned-space ducts are always assigned 0% leakage and uninsulated inputs, their comparison is intentionally a location/boundary comparison, not a quality comparison.

## Input convention for conditioned-space ducts

In these runs, ducts in either `Living Space` or `Heated Basement` are assigned:

```text
0% Leakage to Outside, Uninsulated
```

This is an important modeling convention. It means the conditioned-space cases cannot be used to compare duct quality against unconditioned-space cases. The relevant contrast is where the ducts are located and whether they are inside the heated/conditioned thermal boundary.

The unheated-basement cases vary duct quality because the duct location is outside the conditioned space:

- 0% leakage, uninsulated
- 10% leakage, R-6
- 30% leakage, uninsulated
- 30% leakage, R-6

## How OS-HPXML models ducts

The annual duct model is created in `HPXMLtoOpenStudio/resources/airflow.rb`. For each duct location, it creates EMS-actuated `OtherEquipment` objects, duct-zone `ZoneMixing` objects, and EMS variables for leakage imbalance.

Supply conduction is calculated approximately as:

$$
Q_{\mathrm{sup,cond}} = \dot m c_p (T_{\mathrm{sup,after}} - T_{\mathrm{sup,coil}})
$$

When ducts are colder than the supply air, the supply air loses heat before reaching the conditioned space. Return conduction, supply leakage, and return leakage are calculated separately. Leakage to an unconditioned or outdoor zone is a distribution loss; leakage into a heated zone can be partly retained by the building.

The annual simulation and design sizing use related but distinct calculations:

- **Design sizing:** duct losses reduce distribution effectiveness and increase the design load used to size equipment.
- **Annual simulation:** duct conduction, leakage, and duct-zone mixing are simulated dynamically through EMS.

## Delivered heating and duct component loads

For annual reporting, OS-HPXML combines conditioned-zone and duct-zone EnergyTransfer values into delivered heating. When component loads are enabled, it also reports `Component Load: Heating: Ducts`.

For ducts in living space or a heated basement, the separate duct component can be zero because duct effects are embedded in the conditioned-zone balance. A zero duct component does not mean the duct model has no effect; in these tests it reflects the fact that conditioned-space ducts are inside the heated boundary and are assigned 0% leakage.

For ducts in an unheated basement, the duct zone is modeled separately, so the duct contribution appears explicitly as `Component Load: Heating: Ducts`.

## CFA and foundation-boundary effects

The unheated-basement variants do **not** have lower conditioned floor area. All seven variants report:

```text
ConditionedFloorArea = 1698 ft2
floor_area_conditioned_ft_2 = 1698
```

Therefore, the higher unheated-basement heating load is not caused by reducing CFA.

The foundation thermal boundary does change:

| Foundation treatment | Foundation area |
|---|---:|
| Heated basement | 566 ft2 |
| Unheated basement | 849 ft2 |

Changing from heated to unheated basement changes basement temperatures, foundation surfaces, floor/slab treatment, and duct-zone heat transfer. Thus, the original heated-basement-to-unheated-basement comparison was a combined **foundation-boundary plus duct-location** experiment.

## Results across all seven variants

All variants represent the same basic 1,500-1,999 ft2, 10 ACH50 building and use a ducted heat pump.

| Variant | Foundation | Duct location | Duct quality | Total electricity | Delivered heating | Duct load | Duct / delivered | Backup electricity | Unmet hours |
|---|---|---|---|---:|---:|---:|---:|---:|---:|
| `bldg0029849` | Heated | Heated Basement | 0%, uninsulated | 86.446 MBtu | 74.902 MBtu | 0.000 MBtu | 0.0% | 42.812 MBtu | 50 |
| `bldg0298491` | Heated | Living Space | 0%, uninsulated | 86.599 MBtu | 75.009 MBtu | 0.000 MBtu | 0.0% | 42.999 MBtu | 56 |
| `bldg0298492` | Unheated | Unheated Basement | 0%, uninsulated | 102.856 MBtu | 94.624 MBtu | 27.109 MBtu | 28.6% | 56.342 MBtu | 86 |
| `bldg0298493` | Unheated | Unheated Basement | 10%, R-6 | 96.724 MBtu | 87.625 MBtu | 15.435 MBtu | 17.6% | 50.807 MBtu | 58 |
| `bldg0298494` | Unheated | Unheated Basement | 30%, uninsulated | 106.303 MBtu | 100.792 MBtu | 36.336 MBtu | 36.1% | 59.202 MBtu | 39 |
| `bldg0298495` | Unheated | Unheated Basement | 30%, R-6 | 100.771 MBtu | 92.874 MBtu | 22.850 MBtu | 24.6% | 53.802 MBtu | 30 |
| `bldg0298496` | Unheated | Living Space | 0%, uninsulated | 88.086 MBtu | 79.016 MBtu | 0.000 MBtu | 0.0% | 43.241 MBtu | 76 |

## Controlled comparisons

### Heated foundation: heated basement versus living space

These cases preserve the heated-basement foundation and use the required conditioned-space duct inputs in both cases:

- Total electricity: 86.446 to 86.599 MBtu.
- Delivered heating: 74.902 to 75.009 MBtu.
- Backup electricity: 42.812 to 42.999 MBtu.

The difference is negligible. Ducts in the heated basement behave much like ducts in living space because both are inside the heated thermal boundary for this comparison.

### Unheated foundation: unheated basement versus living space

This is the new and most important comparison:

| Metric | Unheated-basement ducts, `bldg0298492` | Living-space ducts, `bldg0298496` | Difference |
|---|---:|---:|---:|
| Total electricity | 102.856 MBtu | 88.086 MBtu | -14.770 MBtu (-14.4%) |
| Delivered heating | 94.624 MBtu | 79.016 MBtu | -15.608 MBtu (-16.5%) |
| Duct component load | 27.109 MBtu | 0.000 MBtu | -27.109 MBtu |
| Heat-pump backup electricity | 56.342 MBtu | 43.241 MBtu | -13.101 MBtu (-23.3%) |
| Unmet heating hours | 86 | 76 | -10 h |

Because the foundation is unheated in both cases and CFA remains 1,698 ft2, this is strong evidence that the duct location itself is responsible for most of the difference.

The residual difference between the two cases is not expected to equal the duct component load one-for-one. Duct losses alter heat-pump operation, backup staging, fan operation, and the zone temperature balance.

### Unheated-basement duct-quality sweep

#### 10% leakage, R-6 versus 0% leakage, uninsulated

Comparing `bldg0298493` with `bldg0298492`:

- Total electricity: 102.856 to 96.724 MBtu, reduction of 6.132 MBtu.
- Delivered heating: 94.624 to 87.625 MBtu, reduction of 6.999 MBtu.
- Duct load: 27.109 to 15.435 MBtu, reduction of 11.674 MBtu.
- Backup electricity: 56.342 to 50.807 MBtu, reduction of 5.535 MBtu.
- Unmet hours: 86 to 58.

The R-6 case performs better despite having 10% leakage. This indicates that conduction is a major loss mechanism in this particular comparison.

#### 30% leakage, R-6 versus 30% leakage, uninsulated

Comparing `bldg0298495` with `bldg0298494`:

- Total electricity: 106.303 to 100.771 MBtu, reduction of 5.532 MBtu.
- Delivered heating: 100.792 to 92.874 MBtu, reduction of 7.918 MBtu.
- Duct load: 36.336 to 22.850 MBtu, reduction of 13.486 MBtu.
- Backup electricity: 59.202 to 53.802 MBtu, reduction of 5.400 MBtu.
- Unmet hours: 39 to 30.

Again, R-6 insulation substantially reduces the duct penalty even when leakage remains high.

#### 10% leakage, R-6 versus 30% leakage, R-6

Comparing `bldg0298493` with `bldg0298495` isolates the effect of increasing leakage while holding the unheated-basement location and R-6 insulation constant:

- Total electricity: 96.724 to 100.771 MBtu, an increase of 4.047 MBtu.
- Delivered heating: 87.625 to 92.874 MBtu, an increase of 5.249 MBtu.
- Duct load: 15.435 to 22.850 MBtu, an increase of 7.415 MBtu.
- Backup electricity: 50.807 to 53.802 MBtu, an increase of 2.995 MBtu.
- Unmet hours: 58 to 30.

The higher-leakage case has higher energy use and duct load, as expected. Its lower unmet-hour count is not evidence that it performs better: the larger duct penalty also produces a larger design heating capacity, allowing the system to meet more of the load. This illustrates why energy use, delivered load, duct load, equipment capacity, and unmet hours should be interpreted together.

#### 30% leakage versus 0% leakage, both uninsulated

Comparing `bldg0298494` with `bldg0298492`:

- Total electricity: +3.447 MBtu.
- Delivered heating: +6.168 MBtu.
- Duct load: +9.227 MBtu.
- Backup electricity: +2.860 MBtu.

High leakage increases the duct and heating penalties, although its effect is smaller than the insulation effect in these runs.

## Why duct load and site energy do not move one-for-one

Site energy can be represented schematically as:

$$
E_{\mathrm{site}} \approx
\frac{Q_{\mathrm{delivered}}}{\eta_{\mathrm{equipment}}}
+ E_{\mathrm{fans}} + E_{\mathrm{backup}}
$$

A duct loss increases required thermal delivery. During cold hours, it can also push a heat pump toward its capacity limit and cause resistance backup to operate. The resulting increase in backup electricity can be disproportionately large compared with the direct duct load.

If the equipment reaches capacity, additional demand can instead appear as unmet hours rather than additional delivered heat. This explains why duct load, delivered load, backup electricity, and unmet hours need to be examined together.

## Implications for the ND/SD discrepancy

The HDD-normalized delivered-heating plot shows that ND and SD do not have unusually high heating demand. The AIM-2 wind experiment also showed that removing wind reduces heating consumption only modestly. The expanded duct experiment identifies a stronger potential mechanism:

$$
\text{unconditioned duct prevalence}
\times
\text{duct load fraction}
\times
\text{heat-pump backup sensitivity}
$$

However, colder states having better average duct quality does not rule out a duct contribution. A state can have better insulation and leakage averages but still consume more if it has a higher prevalence of ducts outside the conditioned boundary. Location and quality must be analyzed jointly.

The current evidence supports this working interpretation:

> Ducts in unconditioned basements can increase delivered heating load and amplify heat-pump backup electricity. The new same-foundation comparison shows that duct location is a credible contributor independent of CFA reduction or foundation type. The national effect will depend on the weighted prevalence of unconditioned duct locations and the quality distribution within those homes.

## Recommended national-scale follow-up

For a national comparison, use the stock distributions to calculate or approximate:

1. Fraction of homes with ducts in unheated basements or crawlspaces.
2. Fraction with ducts in heated basements or living space.
3. Duct component load per delivered heating load by duct-location segment.
4. Heat-pump backup electricity per delivered heating load by segment.
5. Joint duct-location and duct-quality distributions by state.

The most discriminating small-run result is now `bldg0298492` versus `bldg0298496`: same unheated-basement foundation and same CFA, with ducts moved from the unheated basement to living space. That comparison should be used as the primary estimate of the duct-location penalty.
