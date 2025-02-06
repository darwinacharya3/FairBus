from fastapi import FastAPI, Request
import firebase_admin
from firebase_admin import credentials, firestore

app = FastAPI()

# Initialize Firebase
cred = credentials.Certificate(r"D:\Flutter\Project\major_project\server\firebase_credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Success endpoint
@app.post("/esewa/success")
async def esewa_success(request: Request):
    data = await request.json()  # Get the data from eSewa
    transaction_id = data.get("transaction_id")
    user_id = data.get("user_id")
    amount = data.get("amount")

    # Store the transaction details in Firestore
    if transaction_id and user_id and amount:
        transaction_ref = db.collection("transactions").document(transaction_id)
        transaction_ref.set({
            "user_id": user_id,
            "transaction_id": transaction_id,
            "amount": amount,
            "status": "success"
        })
        return {"message": "Payment successful", "transaction_id": transaction_id}
    
    return {"error": "Invalid payment data"}

# Failure endpoint
@app.post("/esewa/failure")
async def esewa_failure(request: Request):
    data = await request.json()
    transaction_id = data.get("transaction_id")
    user_id = data.get("user_id")

    if transaction_id and user_id:
        transaction_ref = db.collection("transactions").document(transaction_id)
        transaction_ref.set({
            "user_id": user_id,
            "transaction_id": transaction_id,
            "status": "failed"
        })
        return {"message": "Payment failed", "transaction_id": transaction_id}
    
    return {"error": "Invalid failure data"}
























# from fastapi import FastAPI, HTTPException
# from pydantic import BaseModel
# import firebase_admin
# from firebase_admin import credentials, firestore
# import uvicorn

# # Initialize Firebase
# cred = credentials.Certificate("D:\\Flutter\\Project\\major_project\\server\\firebase_credentials.json")
# firebase_admin.initialize_app(cred)
# db = firestore.client()

# app = FastAPI()

# # Payment success request model
# class PaymentSuccess(BaseModel):
#     transaction_id: str
#     user_id: str
#     amount: float
#     status: str

# # Payment failure request model
# class PaymentFailure(BaseModel):
#     user_id: str
#     error_message: str

# @app.post("/esewa/success")
# async def esewa_success(data: PaymentSuccess):
#     try:
#         # Store transaction in Firestore
#         transaction_ref = db.collection("transactions").document(data.transaction_id)
#         transaction_ref.set({
#             "user_id": data.user_id,
#             "amount": data.amount,
#             "status": data.status,
#             "timestamp": firestore.SERVER_TIMESTAMP
#         })
#         return {"message": "Payment recorded successfully"}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# @app.post("/esewa/failure")
# async def esewa_failure(data: PaymentFailure):
#     try:
#         return {"message": f"Payment failed for user {data.user_id}: {data.error_message}"}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# # Run the server
# if __name__ == "__main__":
#     uvicorn.run(app, host="0.0.0.0", port=8000)
