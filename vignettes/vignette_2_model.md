# Vignette: Predictive Model Derivation and Validation

## Overview

Predictive modelling is a fantastically useful statistical technique to
estimate how likely a patient is to have an event, based on the
characteristics of patients similar to them. There are three general
scenarios where you’d want to do predictive modelling:

1.  Development of a novel prediction model.

2.  Validation of a novel prediction model.

3.  (External) Validation of a previous prediction model

## Load data

Firstly let’s load our example data - we will be using the
survival::colon dataset as an example.

    data <- tibble::as_tibble(survival::colon) %>%
      dplyr::filter(etype==2) %>% # Outcome of interest is death
      dplyr::filter(rx!="Obs") %>%  # rx will be our binary treatment variable
      dplyr::select(-etype,-study, -status) %>% # Remove superfluous variables
      
      # Convert into numeric and factor variables
      dplyr::mutate_at(vars(obstruct, perfor, adhere, node4), function(x){factor(x, levels=c(0,1), labels = c("No", "Yes"))}) %>%
      dplyr::mutate(rx = factor(rx),
                    mort365 = cut(time, breaks = c(-Inf, 365, Inf), labels = c("Yes", "No")),
                    mort365 = factor(mort365, levels = c("No", "Yes")),
                    sex = factor(sex, levels=c(0,1), labels = c("Female", "Male")),
                    differ = factor(differ, levels = c(1,2,3), labels = c("Well", "Moderate", "Poor")),
                    extent = factor(extent, levels = c(1,2,3, 4), labels = c("Submucosa", "Muscle", "Serosa", "Contiguous Structures")),
                    surg = factor(surg, levels = c(0,1), labels = c("Short", "Long")))

    head(data, 10) %>% knitr::kable()

<table>
<thead>
<tr>
<th style="text-align:right;">
id
</th>
<th style="text-align:left;">
rx
</th>
<th style="text-align:left;">
sex
</th>
<th style="text-align:right;">
age
</th>
<th style="text-align:left;">
obstruct
</th>
<th style="text-align:left;">
perfor
</th>
<th style="text-align:left;">
adhere
</th>
<th style="text-align:right;">
nodes
</th>
<th style="text-align:left;">
differ
</th>
<th style="text-align:left;">
extent
</th>
<th style="text-align:left;">
surg
</th>
<th style="text-align:left;">
node4
</th>
<th style="text-align:right;">
time
</th>
<th style="text-align:left;">
mort365
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:right;">
43
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Short
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
1521
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:right;">
63
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Short
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
3087
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:right;">
66
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Long
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
293
</td>
<td style="text-align:left;">
Yes
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:right;">
57
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Short
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
1767
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:right;">
77
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Long
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
420
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:right;">
46
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Short
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
3173
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
10
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:right;">
68
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Long
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
3308
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
11
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:right;">
47
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Short
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
2908
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
12
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:right;">
52
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Long
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
3309
</td>
<td style="text-align:left;">
No
</td>
</tr>
<tr>
<td style="text-align:right;">
14
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:right;">
68
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Serosa
</td>
<td style="text-align:left;">
Short
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
2910
</td>
<td style="text-align:left;">
No
</td>
</tr>
</tbody>
</table>

Now let’s split this very simply into development and validation
datasets - this should be done far more robustly in practice!

    data_dev = data %>% head(0.5 * nrow(data))
    data_val = data %>% tail(0.5 * nrow(data))

## Predictive Modelling

### 1. Development of a novel prediction model

Now let’s say we want to create a new logistic regression model (`fit`)
to predict our event (death at 1 year aka “mort365”) based on patient
and operative factors.

-   We’re skipping over the part of how you select your explanatory
    variables as that’s not the focus of this package given it requires
    domain-specific clinical insight.

<!-- -->

    fit <- finalfit::glmmulti(data_dev, dependent = "mort365", explanatory = c("rx", "sex","obstruct", "differ"))

    summary(fit)

    ## 
    ## Call:
    ## glm(formula = ff_formula(dependent, explanatory), family = family, 
    ##     data = .data)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -0.9905  -0.4084  -0.3551  -0.2883   2.7557  
    ## 
    ## Coefficients:
    ##                Estimate Std. Error z value Pr(>|z|)   
    ## (Intercept)     -3.3466     1.0588  -3.161  0.00157 **
    ## rxLev+5FU       -0.2902     0.4397  -0.660  0.50930   
    ## sexMale         -0.4276     0.4396  -0.973  0.33079   
    ## obstructYes      0.6822     0.4922   1.386  0.16573   
    ## differModerate   0.9046     1.0529   0.859  0.39026   
    ## differPoor       2.4976     1.0862   2.299  0.02148 * 
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 176.12  on 295  degrees of freedom
    ## Residual deviance: 161.08  on 290  degrees of freedom
    ##   (11 observations deleted due to missingness)
    ## AIC: 173.08
    ## 
    ## Number of Fisher Scoring iterations: 6

Now we want to get the patient-level predicted risk of the outcome based
on the model - this is needed to evaluate the performance of the model
you have derived (see the next vignettes). This isn’t necessarily
difficult to do in R, but you need to know how to do this.

Using the traditional approach using tidyverse code, you might need to
do something like this:

    # Traditional approach
    data %>%
          dplyr::select(all_of(c("mort365", c("rx", "sex","obstruct", "differ")))) %>%
          tidyr::drop_na() %>%
          dplyr::mutate(predict_raw = predict(fit, newdata  = ., ),
                        predict_prop = predict(fit, type = "response", newdata  = ., )) %>% 
      head(10) %>%
      knitr::kable() %>% kableExtra::scroll_box(width = 400)

<table>
<thead>
<tr>
<th style="text-align:left;">
mort365
</th>
<th style="text-align:left;">
rx
</th>
<th style="text-align:left;">
sex
</th>
<th style="text-align:left;">
obstruct
</th>
<th style="text-align:left;">
differ
</th>
<th style="text-align:right;">
predict\_raw
</th>
<th style="text-align:right;">
predict\_prop
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-3.159698
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-3.159698
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.049911
</td>
<td style="text-align:right;">
0.1140614
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.732142
</td>
<td style="text-align:right;">
0.0611032
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.869505
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.869505
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.732142
</td>
<td style="text-align:right;">
0.0611032
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.441949
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:right;">
-1.566667
</td>
<td style="text-align:right;">
0.1726920
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:right;">
-2.187275
</td>
<td style="text-align:right;">
0.1008991
</td>
</tr>
</tbody>
</table>

The exact same can easily be achieved using the `predictr()` function.
You simply provide the data (`data_dev`), and the model (`fit`), and
this will be done automatically.

    # PredictR approach
    predictr(data = data_dev, fit = fit) %>% 
      head(10) %>%
      knitr::kable() %>% kableExtra::scroll_box(width = 400)

<table>
<thead>
<tr>
<th style="text-align:right;">
rowid
</th>
<th style="text-align:left;">
mort365
</th>
<th style="text-align:left;">
rx
</th>
<th style="text-align:left;">
sex
</th>
<th style="text-align:left;">
obstruct
</th>
<th style="text-align:left;">
differ
</th>
<th style="text-align:left;">
event
</th>
<th style="text-align:right;">
predict\_raw
</th>
<th style="text-align:right;">
predict\_prop
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-3.159698
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-3.159698
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-2.049911
</td>
<td style="text-align:right;">
0.1140614
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.732142
</td>
<td style="text-align:right;">
0.0611032
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.869505
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.869505
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.732142
</td>
<td style="text-align:right;">
0.0611032
</td>
</tr>
<tr>
<td style="text-align:right;">
8
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.441949
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
<tr>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-1.566667
</td>
<td style="text-align:right;">
0.1726920
</td>
</tr>
<tr>
<td style="text-align:right;">
10
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.187275
</td>
<td style="text-align:right;">
0.1008991
</td>
</tr>
</tbody>
</table>

### 2. Validation of a novel prediction model

While people often stop at deriving a new model, you should be testing
whether the model derived (`fit`) is valid on new data.

With `predictr()` this can again be done simply by supplying the new
data (`data_val`) to the function (keeping `fit` unchanged).

-   Please note that you **must** have the original ‘fit’ object for
    this approach to work.

<!-- -->

    predictr(data = data_val, fit = fit) %>% 
      head(10) %>%
      knitr::kable() %>% kableExtra::scroll_box(width = 400)

<table>
<thead>
<tr>
<th style="text-align:right;">
rowid
</th>
<th style="text-align:left;">
mort365
</th>
<th style="text-align:left;">
rx
</th>
<th style="text-align:left;">
sex
</th>
<th style="text-align:left;">
obstruct
</th>
<th style="text-align:left;">
differ
</th>
<th style="text-align:left;">
event
</th>
<th style="text-align:right;">
predict\_raw
</th>
<th style="text-align:right;">
predict\_prop
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Well
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-3.7741169
</td>
<td style="text-align:right;">
0.0224421
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.0499110
</td>
<td style="text-align:right;">
0.1140614
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-0.8489192
</td>
<td style="text-align:right;">
0.2996596
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.8695053
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-1.7597188
</td>
<td style="text-align:right;">
0.1468256
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.4419494
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-0.4568807
</td>
<td style="text-align:right;">
0.3877261
</td>
</tr>
<tr>
<td style="text-align:right;">
8
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.8695053
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:right;">
9
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-3.1596975
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:right;">
10
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.4419494
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
</tbody>
</table>

Once again, this output can be used for model evaluation using the
functions described in subsequent vignettes.

## 3. (External) Validation of a previous prediction model

Now let’s say someone else has developed a model that you now want to
validate (or vice versa). It’s unlikely the R fit object will be shared
in this instance (they may not have used R, and even if they did the fit
object contains a lot of potentially sensitive patient data).

You will often need to use the model coefficents and intercept provided
in a paper to be able to reproduce.

#### Deriving coefficents from fit objects

The normal fit object has coefficients stored in it, but not necessarily
in a massively useful / informative format:

    fit$coefficients

    ##    (Intercept)      rxLev+5FU        sexMale    obstructYes 
    ##     -3.3465610     -0.2901922     -0.4275559      0.6822306 
    ## differModerate     differPoor 
    ##      0.9046116      2.4976418

Instead you can use the `predictr::coefficient()` function to get this
information out in a useful and shareable format. This provides all the
information required for subsequent external validation using the
`predictr()` function, and can be used as an alternative to the `fit`
parameter.

    coefficient(fit) %>% knitr::kable()

<table>
<thead>
<tr>
<th style="text-align:left;">
label
</th>
<th style="text-align:left;">
levels
</th>
<th style="text-align:left;">
type
</th>
<th style="text-align:right;">
value
</th>
<th style="text-align:left;">
coefficient
</th>
<th style="text-align:left;">
outcome
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
rx
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
rx
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
-0.2901922
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
sex
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
sex
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
-0.4275559
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
obstruct
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
obstruct
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
0.6822306
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
differ
</td>
<td style="text-align:left;">
Well
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
differ
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
0.9046116
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
differ
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:right;">
2.4976418
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
<tr>
<td style="text-align:left;">
intercept
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
-3.3465610
</td>
<td style="text-align:left;">
beta
</td>
<td style="text-align:left;">
mort365
</td>
</tr>
</tbody>
</table>

#### Prediction using model coefficients

For coefficents to be used within `predictr()`, this must be in the
format provided by the `coefficient()` function (whether using
`coefficient(fit)` or manually extracting from a publication to create a
table).

    predictr(data = data_val,
             coefficient = coefficient(fit)) %>%
      head(10) %>% knitr::kable()

<table>
<thead>
<tr>
<th style="text-align:left;">
mort365
</th>
<th style="text-align:left;">
rx
</th>
<th style="text-align:left;">
sex
</th>
<th style="text-align:left;">
obstruct
</th>
<th style="text-align:left;">
differ
</th>
<th style="text-align:left;">
event
</th>
<th style="text-align:right;">
predict\_raw
</th>
<th style="text-align:right;">
predict\_prop
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Well
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-3.7741169
</td>
<td style="text-align:right;">
0.0224421
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.0499110
</td>
<td style="text-align:right;">
0.1140614
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-0.8489192
</td>
<td style="text-align:right;">
0.2996596
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.8695053
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-1.7597188
</td>
<td style="text-align:right;">
0.1468256
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.4419494
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-0.4568807
</td>
<td style="text-align:right;">
0.3877261
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.8695053
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-3.1596975
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.4419494
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
</tbody>
</table>

The default approach in `predictr()` is to use beta-coefficents, however
if the paper you have only supplies odds ratios (OR), you can specify
this and `predictr()` will handle this internally to produce the
appropriate predictions.

    predictr(data = data_val,
             coefficient = coefficient(fit, coefficient = "or")) %>%
      head(10) %>% knitr::kable()

<table>
<thead>
<tr>
<th style="text-align:left;">
mort365
</th>
<th style="text-align:left;">
rx
</th>
<th style="text-align:left;">
sex
</th>
<th style="text-align:left;">
obstruct
</th>
<th style="text-align:left;">
differ
</th>
<th style="text-align:left;">
event
</th>
<th style="text-align:right;">
predict\_raw
</th>
<th style="text-align:right;">
predict\_prop
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Well
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-3.7741169
</td>
<td style="text-align:right;">
0.0224421
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.0499110
</td>
<td style="text-align:right;">
0.1140614
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-0.8489192
</td>
<td style="text-align:right;">
0.2996596
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.8695053
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-1.7597188
</td>
<td style="text-align:right;">
0.1468256
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.4419494
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Poor
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-0.4568807
</td>
<td style="text-align:right;">
0.3877261
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.8695053
</td>
<td style="text-align:right;">
0.0536818
</td>
</tr>
<tr>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:left;">
Lev+5FU
</td>
<td style="text-align:left;">
Male
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
Yes
</td>
<td style="text-align:right;">
-3.1596975
</td>
<td style="text-align:right;">
0.0407109
</td>
</tr>
<tr>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Lev
</td>
<td style="text-align:left;">
Female
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:left;">
Moderate
</td>
<td style="text-align:left;">
No
</td>
<td style="text-align:right;">
-2.4419494
</td>
<td style="text-align:right;">
0.0800293
</td>
</tr>
</tbody>
</table>
