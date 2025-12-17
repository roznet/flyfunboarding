"""
Status API router.

Matches PHP StatusController endpoint.
"""
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import DbSession

router = APIRouter()


@router.get("")
async def get_status(db: DbSession):
    """
    Get database status.
    
    Matches PHP: GET /v1/status
    Returns 200 with status=true if database is accessible, 404 with status=false otherwise.
    """
    try:
        # Check if Airlines table exists (same as PHP status() method)
        query = text("SHOW TABLES LIKE 'Airlines'")
        result = await db.execute(query)
        row = result.fetchone()
        
        if row:
            status_value = True
            message = "OK"
            status_code = status.HTTP_200_OK
        else:
            status_value = False
            message = "Error"
            status_code = status.HTTP_404_NOT_FOUND
            
    except Exception as e:
        status_value = False
        message = f"code: {getattr(e, 'code', 'unknown')}"
        status_code = status.HTTP_404_NOT_FOUND
    
    response_data = {
        "status": status_value,
        "message": message
    }
    
    if status_value:
        return response_data
    else:
        raise HTTPException(status_code=status_code, detail=response_data)

