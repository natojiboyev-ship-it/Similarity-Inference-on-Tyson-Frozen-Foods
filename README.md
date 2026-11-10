# Tyson sales simulation code

This repository contains the six Python notebooks used to evaluate exception selection and similarity-based inference on the Tyson Frozen Foods sales data. It covers the main sales comparisons in Tables 1, 2, 4, and 6. The notebooks apply the simulation design, including error seeding, to an input extracted from the teaching-case database.

## Obtain the teaching-case database

1. Open [Walton College’s Tyson Frozen Foods page](https://walton.uark.edu/enterprise/tysonhome.php) and find **A Teaching Case-Study**. Follow the [teaching-case download link published by Walton College](https://uark.app.box.com/s/39cpw0ciit3r9czvh48bcawz1iwzne9y) for the 2007 Microsoft Access database. Extract the download if it is provided as an archive.
2. Locate the `.accdb` file containing `INVOICE_FACT`. The source database has 2,144,075 rows in that table. Keep the database locally and pass its path to the extraction script below.

Walton College distributes the teaching-case extract separately. It describes the full Tyson dataset as access-controlled within the university’s computing environment and subject to a download prohibition. This workflow uses the teaching-case extract. The proprietary payroll dataset is subject to separate access conditions.

The extraction script and direct Access loader use the same query.

```sql
SELECT *
FROM INVOICE_FACT
WHERE INVOICE_DAY_KEY BETWEEN 827045 AND 827047;
```

The query returns **17,440 invoice lines** from **6,029 distinct customers**. The counts for day keys `827045`, `827046`, and `827047` are 5,863, 5,785, and 5,792, respectively.

## Set up the environment

Use Windows, 64-bit Python 3.9.13, and the 64-bit Microsoft Access ODBC driver. If needed, see [Microsoft’s Access Runtime installation guide](https://support.microsoft.com/en-us/access/download-and-install-microsoft-365-access-runtime). The driver must match the bitness of Python. `requirements.txt` lists the direct package versions from the original working environment.

Open 64-bit PowerShell in the repository folder. Prepare the data by replacing the example path below with your Access file. The script uses the Access ODBC driver and writes `data/tyson-invoice-lines.csv` in the original query order.

```powershell
.\extract_tyson.ps1 -DatabasePath 'C:\path\to\the\teaching-case.accdb'
```

With Python 3.9.13 available as `python`, run the following commands.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m jupyterlab
```

Open each notebook with the Python kernel from this environment, restart the kernel, and run the cells from top to bottom. Each notebook loads and seeds the source data independently. The reported analyses use **100 replications per setting** and an investigation limit of **100 exceptions per replication**. The notebooks construct dense pairwise distance matrices, so full runs require several gigabytes of available memory.

To read an extracted CSV at a different location, set `$env:TYSON_CSV_PATH` before launching Jupyter. For direct Access loading, set `$env:TYSON_DB_PATH` to the `.accdb` file and start with an empty `data/` folder. The notebook uses the extracted CSV when present and otherwise connects to Access.

## Run settings and output

| Reported sales analysis | Notebooks | Settings |
| --- | --- | --- |
| Table 1, inference accuracy under Classic selection | `Tyson_Filters - Classic - Auto.ipynb` | In a separate copy, set the starting similarity threshold and its increment to `0.001`. Keep the upper limit at `0.020`. Table 1 reports `0.001`, `0.005`, `0.010`, `0.015`, and `0.020`. |
| Tables 2 and 4, distance thresholds | Classic, Skipper, and Agglomerative by Similarity | Use the supplied grid `0`, `0.002`, …, `0.020`. |
| Table 6, risk score cutoffs | Stretcher, K Means, and Agglomerative by Risk | Use the supplied grid `600`, `650`, …, `1100`. |

The notebooks write dated Excel workbooks to `results/`. Each workbook contains `Output`, `Mean Summary`, and `Std Summary`. The `Output` sheet contains one row per threshold and replication. For the separate Classic run for Table 1, choose a different output directory by setting `$env:TYSON_RESULTS_DIR = 'results/table-1'` before launching Jupyter. This keeps the two Classic workbooks separate if both runs are performed on the same day.

The seeding code sets Python’s random seed from the replication number. The original Access query relies on the database’s returned row order, and the K-means implementation uses the library’s default random initialization. Use the documented environment and preserve the input row order when comparing results with the reported summaries. Small differences in runs can arise from row ordering or clustering initialization.
