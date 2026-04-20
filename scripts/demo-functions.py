
"""
title: Assistant Météo
description: Fournit la météo pour une ville donnée (démo section 9.3)
author: Démo Open WebUI
version: 1.0.0
"""

import requests
from typing import Optional, Dict, Any

class Tool:
    def __init__(self):
        self.id = "weather_assistant"
        self.name = "Météo"
        self.description = "Obtenir la météo actuelle pour une ville"

    async def get_weather(self, city: str, country: str = "FR") -> Dict[str, Any]:
        """
        Récupère la météo pour une ville.
        
        Args:
            city: Nom de la ville
            country: Code pays (par défaut FR)
        
        Returns:
            Dict contenant la météo
        """
        # API de démo (remplacer par une vraie API en production)
        weather_data = {
            "city": city,
            "temperature": 22,
            "condition": "Ensoleillé",
            "humidity": 65,
            "wind_speed": 12
        }
        
        return {
            "success": True,
            "data": weather_data,
            "message": f"Météo à {city}: {weather_data['temperature']}°C, {weather_data['condition']}"
        }

    async def execute(self, **kwargs) -> str:
        city = kwargs.get("city", "Paris")
        result = await self.get_weather(city)
        return result["message"]

# Pour tester dans Open WebUI
if __name__ == "__main__":
    tool = Tool()
    import asyncio
    print(asyncio.run(tool.get_weather("Paris")))