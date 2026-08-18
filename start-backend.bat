@echo off
cd /d "D:\Quater-5\A-Gaffar meat shop\backend"
echo Starting AGMS Backend on port 8000...
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
pause
