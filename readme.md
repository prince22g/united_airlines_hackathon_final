# United Airlines - Flight Difficulty Score

## 📝 Introduction & Objective

Frontline teams at United Airlines are responsible for ensuring every flight departs on time. However, not all flights are equally complex. This project addresses the need for a systematic, data-driven approach to identify high-difficulty flights before they become operational challenges.

The goal is to design and implement a **Flight Difficulty Score** that quantifies the relative complexity of each flight departing from Chicago O’Hare (ORD). This score enables proactive planning and optimized resource allocation by identifying the primary operational drivers contributing to flight difficulty.

---

##  Methodology

The analysis was conducted in a Jupyter Notebook using Python with the pandas, scikit-learn, and matplotlib libraries. The workflow was as follows:

1.  **Data Loading & Cleaning:** Loaded five datasets (`Flight Level`, `PNR`, `Baggage`, etc.). Cleaned the data by converting data types, handling missing values, and critically, **removing 23 duplicate flight records** to ensure data integrity.
2.  **Data Aggregation:** Transformed granular PNR, baggage, and special service request (SSR) data to a unique, flight-level view. This was achieved using a robust **merge-then-aggregate** strategy to correctly link records to a specific flight instance (flight number + scheduled departure time).
3.  **Feature Engineering:** Created new, insightful features to quantify operational complexity, including:
    * `departure_delay`: The primary outcome metric.
    * `passenger_load_factor`: The percentage of seats filled.
    * `ground_time_pressure`: The buffer between scheduled ground time and the minimum required turn time.
    * `transfer_bag_ratio`: The proportion of transfer bags to total bags, measuring baggage handling complexity.
4.  **Exploratory Data Analysis (EDA):** Investigated the relationships between these features and operational outcomes to identify the strongest drivers of difficulty.
5.  **Score Development:** Built a weighted difficulty score by normalizing the selected features using `MinMaxScaler` and applying weights based on the EDA findings.
6.  **Ranking & Classification:** Ranked flights daily by their difficulty score and classified them into three tiers: **Difficult, Medium, and Easy**.

---

## 📊 Exploratory Data Analysis (EDA)

This analysis answered key operational questions, revealing the underlying drivers of flight difficulty.

#### 1. What is the average delay and what percentage of flights depart later than scheduled?

* **Average Departure Delay:** **21.19 minutes**
* **Percentage of Late Flights:** **49.65%**
* **Significance:** This establishes a baseline for the operational challenge at ORD. With nearly half of all flights departing late, any proactive measure to reduce the average delay of over 20 minutes can have a significant positive impact on the entire network, improving customer satisfaction and reducing downstream costs.

#### 2. How many flights have scheduled ground time close to or below the minimum turn time?

* A total of **621 flights** (7.7% of the total) had a scheduled ground time *below* the minimum required.
* **Significance:** This is a critical finding. It means a significant portion of the schedule is operationally compromised from the start. These flights have no buffer for unforeseen issues, making them inherently high-risk and prime candidates for proactive monitoring. This validates `ground_time_pressure` as a key feature for the difficulty score.

#### 3. What is the average ratio of transfer bags vs. checked bags across flights?

* The average ratio of transfer bags to checked (origin) bags is **3.05**.
* **Significance:** This highlights that baggage complexity at a hub like ORD is driven more by connection logistics than by the number of local passengers. A high ratio points to a flight that is a critical node in the baggage network, increasing the risk of mishandling or delays while waiting for connecting bags.

#### 4. How do passenger loads compare, and do they correlate with delays?

* There is a **weak negative correlation of -0.16** between `passenger_load_factor` and `departure_delay`.
* **Significance:** This counter-intuitive insight proves that the simple assumption "fuller flights equal more delays" is incorrect. It suggests that the airline may already allocate more experienced crews or streamlined processes to its most profitable (fullest) flights. This confirms that passenger load alone is not a sufficient predictor of difficulty and must be considered alongside other factors.

*<p align="center">Passenger Load Factor vs. Departure Delay</p>*
![Passenger Load Factor vs. Departure Delay](./docs/images/passenger%20load%20factor%20vs%20departure%20delay.png)

#### 5. Are high SSR flights also high-delay after controlling for passenger load?

* **Yes, decisively.** At every level of passenger load (Medium, High, and Very High), flights with a greater number of Special Service Requests (SSRs) experience significantly higher average departure delays.
* **Significance:** This is a powerful insight. It isolates `ssr_count` as an **independent driver of complexity**. It’s not just that full flights have more SSRs; even when comparing two equally full flights, the one with more special requests (e.g., wheelchairs, unaccompanied minors) is statistically more likely to be delayed. This provides a strong, data-backed justification for including `ssr_count` in the difficulty score.

*<p align="center">Impact of SSRs on Delay, Controlled for Passenger Load</p>*
![Impact of SSRs on Delay, Controlled for Passenger Load](./docs/images/Impact%20of%20SSRs%20on%20Delay,%20Controlled%20for%20Passenger%20Load.png)

---

## 🔢 Flight Difficulty Score Development

The difficulty score is a weighted sum of normalized features identified as key drivers of complexity.

#### Feature Selection and Weighting

Features were scaled from 0 to 1. `ground_time_pressure` was inverted, so a smaller time buffer results in a higher score. Weights were assigned based on EDA findings.

| Feature                   | Weight | Justification                                                      |
| :------------------------ | :----: | :----------------------------------------------------------------- |
| `ground_time_pressure`    |  30%   | The strongest indicator of pre-existing operational risk.          |
| `transfer_bag_ratio`      |  20%   | High transfer volume creates significant baggage handling strain.  |
| `ssr_count`               |  15%   | Proven to directly correlate with higher delays, independent of load. |
| `passenger_load_factor`   |  15%   | Fuller flights increase general complexity and boarding time.      |
| `hot_transfer`            |  10%   | Time-sensitive bags with tight connections add an extra pressure layer. |
| `child_count`             |   5%   | More children can slow the boarding and deplaning process.         |
| `lap_child_count`         |   5%   | Adds minor gate-side documentation and seating complexity.         |

#### Outputs

1.  **Ranking (`daily_difficulty_rank`):** Flights are ranked each day, with rank `1.0` being the most difficult.
2.  **Classification (`difficulty_class`):** Flights are categorized as **Difficult** (top 30%), **Medium** (next 50%), or **Easy** (bottom 20%) based on their daily rank.

---

## 💡 Post-Analysis & Operational Insights

#### Top 10 Most Difficult Destinations from ORD

The analysis reveals that operational difficulty is concentrated on specific routes. Flights to **St. Louis (STL)** are consistently the most challenging.

| Arrival Airport | Count of 'Difficult' Flights |
| :-------------- | :---------------------------: |
| STL             |              88               |
| DTW             |              54               |
| GRR             |              53               |
| DSM             |              53               |
| MSP             |              51               |
| DAY             |              51               |
| CLE             |              49               |
| CID             |              49               |
| OMA             |              48               |
| SEA             |              45               |

#### Common Drivers for Difficult Flights to St. Louis (STL)

A deep dive into the STL route reveals two primary drivers compared to the airport-wide average:

1.  **Ground Time Pressure:** Difficult flights to STL have **~51% less ground time buffer**. They are operationally constrained before the turnaround process even begins.
2.  **Baggage Complexity:** These flights handle a **~50% higher ratio of transfer bags**, indicating intense pressure on the baggage handling system.

---

## 🚀 Actionable Recommendations

Based on these findings, we propose a shift from a reactive to a proactive operational model with the following targeted actions:

1.  **Create a "Proactive Operations Team" for High-Pressure Turnarounds.**
    * **Action:** Each morning, use the Flight Difficulty Score to identify the top 5 flights with severe `ground_time_pressure`. Assign a dedicated team to these flights to ensure all pre-departure tasks (fueling, catering, cleaning) are completed ahead of schedule.
    * **Justification:** This is a high-ROI, targeted use of resources that mitigates the #1 risk factor for delays.

2.  **Implement a "Priority Transfer Bag" Protocol.**
    * **Action:** For flights flagged as 'Difficult' due to a high `transfer_bag_ratio`, instruct baggage handlers to unload and transport bags for these flights first from connecting aircraft.
    * **Justification:** This directly reduces the risk of holding a flight for late bags, a common cause of delays, and improves customer satisfaction by reducing mishandled baggage.

3.  **Launch a Pilot Program Focused on the ORD-STL Route.**
    * **Action:** Roll out the recommendations above as a one-month pilot program exclusively for flights to St. Louis. Track on-time performance and average delay metrics against the baseline established in this analysis.
    * **Justification:** A successful pilot will provide a quantifiable business case to expand these data-driven strategies to other difficult routes across the network.

---

## ⚙️ How to Run

1.  **Prerequisites:**
    * Python 3.x
    * Jupyter Notebook or JupyterLab
    * Required libraries: `pandas`, `numpy`, `scikit-learn`, `matplotlib`, `seaborn` (`pip install pandas numpy scikit-learn matplotlib seaborn`)
2.  **Data:**
    * Place all five provided `.csv` files into a `data` folder located one level above the notebook directory (`../data/`).
3.  **Execution:**
    * Run all cells in the `notebook1.ipynb` notebook from top to bottom. The final output file will be generated in the root directory.

---

## 📁 Final Output

The project generates a CSV file named `test_yourname1.csv` containing the flight details, the features used for the score, and the final difficulty metrics.

**File Preview (`test_yourname1.csv`):**
```csv
flight_number,scheduled_departure_datetime_local,scheduled_arrival_station_code,ground_time_pressure,passenger_load_factor,transfer_bag_ratio,ssr_count,hot_transfer,child_count,lap_child_count,difficulty_score,daily_difficulty_rank,difficulty_class
4792,2025-08-04 17:57:00+00:00,ROA,8.0,0.8552631578947368,0.47619047619047616,3.0,16,1,0,0.5412000551062089,297.0,Medium
920,2025-08-03 18:05:00+00:00,LHR,90.0,1.0,0.2587412587412587,3.0,16,5,1,0.5318833075204489,387.0,Medium
1776,2025-08-10 18:20:00+00:00,PHL,25.0,1.0,0.4470588235294118,0.0,1,5,0,0.5368115456254719,365.0,Medium
5790,2025-08-06 18:20:00+00:00,CRW,194.0,1.0,0.7407407407407407,2.0,0,2,0,0.6010603886561186,99.0,Difficult
1398,2025-08-05 18:20:00+00:00,ATL,24.0,0.8192771084337349,0.7285714285714285,2.0,0,3,0,0.572437346808794,233.0,Medium
...
```