from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import json
import requests
import uuid
import asyncpg
from datetime import date, datetime

import logging
logging.basicConfig(level=logging.DEBUG)

app = FastAPI()

# CORS для Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ========== ПОДКЛЮЧЕНИЕ К БД ==========
DATABASE_URL = "postgresql://nagdarnik:qweasd963@localhost:5432/plusaura_db"

async def get_db():
    """Создает подключение к БД"""
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        yield conn
    finally:
        await conn.close()

# ========== МОДЕЛИ ==========
class UserRegister(BaseModel):
    name: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserData(BaseModel):
    age: int
    gender: str
    height: float
    weight: float
    goal: str
    activity_level: str
    allergies: List[str] = []
    diet_type: str = "none"

class TaskCreate(BaseModel):
    title: str
    task_time: Optional[str] = ""
    task_date: date

class MealCreate(BaseModel):
    meal_date: date
    meal_type: str
    food_name: str
    calories: int
    proteins: float
    fats: float
    carbs: float

class WorkoutCreate(BaseModel):
    workout_date: date
    title: str
    duration: int
    exercises: List[dict]

# ========== GigaChat НАСТРОЙКИ ==========
AUTHORIZATION_KEY = "Basic MDE5ZGM5NTktMmQ1NC03NmU5LWEwMWQtMjdjZjQyZTZmNWU5OmQ0MjU0MmM0LTI1ZTEtNDRkOS04YWRlLTQ2M2U2ZTVjMjYwZQ=="  # ЗАМЕНИ!

def get_giga_token():
    url = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
        "RqUID": str(uuid.uuid4()),
        "Authorization": AUTHORIZATION_KEY
    }
    data = {"scope": "GIGACHAT_API_PERS"}
    response = requests.post(url, headers=headers, data=data, verify=False)
    if response.status_code == 200:
        return response.json()["access_token"]
    raise Exception("Ошибка получения токена")

def build_prompt(user: UserData) -> str:
    gender = "Женщина" if user.gender == "female" else "Мужчина"
    goal = "похудение" if user.goal == "weight_loss" else "набор мышечной массы" if user.goal == "muscle_gain" else "поддержание веса"
    activity_map = {"sedentary": "Сидячий", "light": "Легкая", "moderate": "Умеренная", "active": "Высокая"}
    activity = activity_map.get(user.activity_level, "Умеренная")
    allergies = ", ".join(user.allergies) if user.allergies else "Нет"
    diet_map = {"none": "Без ограничений", "vegetarian": "Вегетарианство", "vegan": "Веганство", "gluten_free": "Без глютена"}
    diet = diet_map.get(user.diet_type, "Без ограничений")
    
    return f"""Ты профессиональный диетолог. Составь персонализированный план питания на 7 дней.

Данные пользователя:
- Пол: {gender}
- Возраст: {user.age} лет
- Рост: {user.height} см
- Вес: {user.weight} кг
- Цель: {goal}
- Уровень активности: {activity}
- Тип питания: {diet}
- Аллергии/исключения: {allergies}

Формат ответа: ТОЛЬКО JSON:
{{
  "calories": число,
  "protein": число,
  "fats": число,
  "carbs": число,
  "weekly_plan": {{
    "Понедельник": {{"Завтрак": "блюдо", "Обед": "блюдо", "Ужин": "блюдо", "Перекус": "блюдо"}},
    "Вторник": {{...}},
    "Среда": {{...}},
    "Четверг": {{...}},
    "Пятница": {{...}},
    "Суббота": {{...}},
    "Воскресенье": {{...}}
  }}
}}"""

# ========== API ЭНДПОИНТЫ ==========

@app.post("/register")
async def register(user: UserRegister, conn: asyncpg.Connection = Depends(get_db)):
    print("=" * 50)
    print("ПОЛУЧЕН ЗАПРОС НА РЕГИСТРАЦИЮ")
    print(f"name: {user.name}")
    print(f"email: {user.email}")
    print(f"password: {user.password}")
    print("=" * 50)
    try:
        await conn.execute(
            "INSERT INTO users (name, email, password) VALUES ($1, $2, $3)",
            user.name, user.email, user.password
        )
        return {"success": True, "message": "Пользователь создан"}
    except Exception as e:
        print(f"ОШИБКА: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/login")
async def login(user: UserLogin, conn: asyncpg.Connection = Depends(get_db)):
    print("=" * 50)
    print("ПОЛУЧЕН ЗАПРОС НА ЛОГИН")
    print(f"email: {user.email}")
    print(f"password: {user.password}")
    print("=" * 50)
    result = await conn.fetchrow(
        "SELECT id, name FROM users WHERE email = $1 AND password = $2",
        user.email, user.password
    )
    if result:
        return {"success": True, "user_id": result["id"], "name": result["name"]}
    raise HTTPException(status_code=401, detail="Неверный email или пароль")

@app.post("/generate_meal_plan")
async def generate_meal_plan(user: UserData, conn: asyncpg.Connection = Depends(get_db)):
    """Генерация плана питания через GigaChat с сохранением данных пользователя"""
    try:
        # ВРЕМЕННО: получаем ID последнего пользователя (потом заменим на реальный из токена)
        user_id_result = await conn.fetchrow("SELECT id FROM users ORDER BY id DESC LIMIT 1")
        user_id = user_id_result["id"] if user_id_result else 1
        
        print(f"🔍 Сохраняем данные для user_id={user_id}")
        print(f"📊 Данные: возраст={user.age}, рост={user.height}, вес={user.weight}, цель={user.goal}, активность={user.activity_level}")
        
        # 1. Обновляем данные пользователя
        await conn.execute(
            """UPDATE users 
               SET age = $1, height = $2, weight = $3, goal = $4, activity_level = $5 
               WHERE id = $6""",
            user.age, user.height, user.weight, user.goal, user.activity_level, user_id
        )
        print(f"✅ Данные пользователя сохранены!")
        
        # 2. Получаем токен GigaChat
        token = get_giga_token()
        
        # 3. Запрос к GigaChat
        url = "https://gigachat.devices.sberbank.ru/api/v1/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"Bearer {token}"
        }
        
        response = requests.post(url, headers=headers, json={
            "model": "GigaChat",
            "messages": [
                {"role": "system", "content": "Ты профессиональный диетолог. Отвечаешь только JSON."},
                {"role": "user", "content": build_prompt(user)}
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        }, verify=False)
        
        if response.status_code == 200:
            content = response.json()["choices"][0]["message"]["content"]
            content = content.strip()
            if content.startswith("```json"): content = content[7:]
            if content.startswith("```"): content = content[3:]
            if content.endswith("```"): content = content[:-3]
            content = content.strip()
            plan = json.loads(content)
            
            # 4. Сохраняем план питания в БД
            await conn.execute(
                """INSERT INTO meal_plans (user_id, calories, protein, fats, carbs, weekly_plan) 
                   VALUES ($1, $2, $3, $4, $5, $6)""",
                user_id, plan["calories"], plan["protein"], plan["fats"], plan["carbs"], 
                json.dumps(plan["weekly_plan"])
            )
            print(f"✅ План питания сохранён: {plan['calories']} ккал")
            
            return plan
        else:
            print(f"❌ Ошибка GigaChat: {response.status_code}")
            return _get_demo_plan()
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return _get_demo_plan()
    
    
@app.post("/tasks")
async def create_task(task: TaskCreate, conn: asyncpg.Connection = Depends(get_db)):
    """Создание задачи"""
    await conn.execute(
        "INSERT INTO tasks (user_id, title, task_time, task_date) VALUES ($1, $2, $3, $4)",
        1, task.title, task.task_time, task.task_date
    )
    return {"success": True}

@app.get("/tasks/{task_date}")
async def get_tasks(task_date: date, conn: asyncpg.Connection = Depends(get_db)):
    """Получение задач на дату"""
    rows = await conn.fetch(
        "SELECT id, title, task_time, completed FROM tasks WHERE user_id = $1 AND task_date = $2 ORDER BY task_time",
        1, task_date
    )
    return [{"id": r["id"], "title": r["title"], "time": r["task_time"], "completed": r["completed"]} for r in rows]

@app.post("/meals")
async def create_meal(meal: MealCreate, conn: asyncpg.Connection = Depends(get_db)):
    """Добавление приёма пищи"""
    await conn.execute(
        """INSERT INTO meals (user_id, meal_date, meal_type, food_name, calories, proteins, fats, carbs) 
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)""",
        1, meal.meal_date, meal.meal_type, meal.food_name, meal.calories, meal.proteins, meal.fats, meal.carbs
    )
    return {"success": True}

@app.get("/meals/{meal_date}")
async def get_meals(meal_date: date, conn: asyncpg.Connection = Depends(get_db)):
    """Получение приёмов пищи за дату"""
    rows = await conn.fetch(
        "SELECT * FROM meals WHERE user_id = $1 AND meal_date = $2",
        1, meal_date
    )
    return [dict(r) for r in rows]

@app.post("/workouts")
async def create_workout(workout: WorkoutCreate, conn: asyncpg.Connection = Depends(get_db)):
    """Создание тренировки"""
    async with conn.transaction():
        workout_id = await conn.fetchval(
            "INSERT INTO workouts (user_id, workout_date, title, duration) VALUES ($1, $2, $3, $4) RETURNING id",
            1, workout.workout_date, workout.title, workout.duration
        )
        for ex in workout.exercises:
            await conn.execute(
                "INSERT INTO workout_exercises (workout_id, exercise_name, sets, reps, weight) VALUES ($1, $2, $3, $4, $5)",
                workout_id, ex["name"], ex["sets"], ex["reps"], ex["weight"]
            )
    return {"success": True}

@app.get("/workouts/{workout_date}")
async def get_workouts(workout_date: date, conn: asyncpg.Connection = Depends(get_db)):
    """Получение тренировок за дату"""
    rows = await conn.fetch(
        "SELECT * FROM workouts WHERE user_id = $1 AND workout_date = $2",
        1, workout_date
    )
    return [dict(r) for r in rows]

def _get_demo_plan():
    return {
        "calories": 2200,
        "protein": 120,
        "fats": 70,
        "carbs": 250,
        "weekly_plan": {
            "Понедельник": {"Завтрак": "Овсянка с ягодами", "Обед": "Куриная грудка с гречкой", "Ужин": "Рыба на пару", "Перекус": "Яблоко"},
            "Вторник": {"Завтрак": "Яичница с авокадо", "Обед": "Салат с тунцом", "Ужин": "Говядина с овощами", "Перекус": "Йогурт"},
            "Среда": {"Завтрак": "Творожная запеканка", "Обед": "Суп-пюре из тыквы", "Ужин": "Куриные котлеты", "Перекус": "Банан"},
            "Четверг": {"Завтрак": "Смузи из шпината", "Обед": "Рис с овощами и тофу", "Ужин": "Индейка с киноа", "Перекус": "Морковь"},
            "Пятница": {"Завтрак": "Панкейки из овсяной муки", "Обед": "Лосось с овощами", "Ужин": "Салат Цезарь", "Перекус": "Груша"},
            "Суббота": {"Завтрак": "Омлет с грибами", "Обед": "Борщ с курицей", "Ужин": "Стейк из лосося", "Перекус": "Смузи ягодный"},
            "Воскресенье": {"Завтрак": "Рисовая каша с тыквой", "Обед": "Запечённая курица", "Ужин": "Рагу из овощей", "Перекус": "Фруктовый салат"}
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)