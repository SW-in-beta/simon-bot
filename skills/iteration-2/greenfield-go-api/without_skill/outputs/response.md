# Simulated Claude Code Response (Without Skill)

---

좋습니다! Go + Gin + PostgreSQL로 사용자 관리, 게시판, 알림 기능이 있는 REST API 서버를 만들어 보겠습니다.

먼저 프로젝트 구조를 잡고 시작하겠습니다.

## 프로젝트 구조

```
api-server/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── config/
│   │   └── config.go
│   ├── database/
│   │   └── postgres.go
│   ├── handler/
│   │   ├── user.go
│   │   ├── post.go
│   │   └── notification.go
│   ├── middleware/
│   │   └── auth.go
│   ├── model/
│   │   ├── user.go
│   │   ├── post.go
│   │   └── notification.go
│   ├── repository/
│   │   ├── user.go
│   │   ├── post.go
│   │   └── notification.go
│   ├── router/
│   │   └── router.go
│   └── service/
│       ├── user.go
│       ├── post.go
│       └── notification.go
├── migrations/
│   ├── 001_create_users.sql
│   ├── 002_create_posts.sql
│   └── 003_create_notifications.sql
├── go.mod
├── go.sum
└── .env
```

주요 파일들을 하나씩 만들어 보겠습니다.

### 1. 프로젝트 초기화

```bash
mkdir -p api-server && cd api-server
go mod init api-server
go get github.com/gin-gonic/gin
go get github.com/lib/pq
go get github.com/jmoiron/sqlx
go get github.com/golang-jwt/jwt/v5
go get golang.org/x/crypto
go get github.com/joho/godotenv
```

### 2. 환경 설정 (.env)

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=api_server
DB_SSLMODE=disable
JWT_SECRET=your-secret-key
SERVER_PORT=8080
```

### 3. 설정 파일 (internal/config/config.go)

```go
package config

import (
    "os"

    "github.com/joho/godotenv"
)

type Config struct {
    DBHost     string
    DBPort     string
    DBUser     string
    DBPassword string
    DBName     string
    DBSSLMode  string
    JWTSecret  string
    ServerPort string
}

func Load() (*Config, error) {
    godotenv.Load()

    return &Config{
        DBHost:     getEnv("DB_HOST", "localhost"),
        DBPort:     getEnv("DB_PORT", "5432"),
        DBUser:     getEnv("DB_USER", "postgres"),
        DBPassword: getEnv("DB_PASSWORD", "password"),
        DBName:     getEnv("DB_NAME", "api_server"),
        DBSSLMode:  getEnv("DB_SSLMODE", "disable"),
        JWTSecret:  getEnv("JWT_SECRET", "secret"),
        ServerPort: getEnv("SERVER_PORT", "8080"),
    }, nil
}

func getEnv(key, fallback string) string {
    if val := os.Getenv(key); val != "" {
        return val
    }
    return fallback
}
```

### 4. 데이터베이스 연결 (internal/database/postgres.go)

```go
package database

import (
    "fmt"

    "github.com/jmoiron/sqlx"
    _ "github.com/lib/pq"

    "api-server/internal/config"
)

func Connect(cfg *config.Config) (*sqlx.DB, error) {
    dsn := fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
        cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBSSLMode,
    )

    db, err := sqlx.Connect("postgres", dsn)
    if err != nil {
        return nil, fmt.Errorf("failed to connect to database: %w", err)
    }

    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)

    return db, nil
}
```

### 5. 모델 (internal/model/)

**user.go:**
```go
package model

import "time"

type User struct {
    ID        int64     `json:"id" db:"id"`
    Email     string    `json:"email" db:"email"`
    Username  string    `json:"username" db:"username"`
    Password  string    `json:"-" db:"password"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
    UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type CreateUserRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Username string `json:"username" binding:"required,min=3,max=50"`
    Password string `json:"password" binding:"required,min=8"`
}

type LoginRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
    Token string `json:"token"`
    User  User   `json:"user"`
}
```

**post.go:**
```go
package model

import "time"

type Post struct {
    ID        int64     `json:"id" db:"id"`
    UserID    int64     `json:"user_id" db:"user_id"`
    Title     string    `json:"title" db:"title"`
    Content   string    `json:"content" db:"content"`
    Author    string    `json:"author,omitempty" db:"username"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
    UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type CreatePostRequest struct {
    Title   string `json:"title" binding:"required,min=1,max=200"`
    Content string `json:"content" binding:"required"`
}

type UpdatePostRequest struct {
    Title   *string `json:"title" binding:"omitempty,min=1,max=200"`
    Content *string `json:"content"`
}

type PostListResponse struct {
    Posts      []Post `json:"posts"`
    TotalCount int    `json:"total_count"`
    Page       int    `json:"page"`
    PageSize   int    `json:"page_size"`
}
```

**notification.go:**
```go
package model

import "time"

type Notification struct {
    ID        int64     `json:"id" db:"id"`
    UserID    int64     `json:"user_id" db:"user_id"`
    Type      string    `json:"type" db:"type"`
    Message   string    `json:"message" db:"message"`
    IsRead    bool      `json:"is_read" db:"is_read"`
    RefID     *int64    `json:"ref_id,omitempty" db:"ref_id"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type NotificationListResponse struct {
    Notifications []Notification `json:"notifications"`
    UnreadCount   int            `json:"unread_count"`
}
```

### 6. Repository 계층 (internal/repository/)

**user.go:**
```go
package repository

import (
    "context"

    "github.com/jmoiron/sqlx"

    "api-server/internal/model"
)

type UserRepository struct {
    db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user *model.User) error {
    query := `INSERT INTO users (email, username, password) VALUES ($1, $2, $3) RETURNING id, created_at, updated_at`
    return r.db.QueryRowContext(ctx, query, user.Email, user.Username, user.Password).
        Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
}

func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*model.User, error) {
    var user model.User
    err := r.db.GetContext(ctx, &user, "SELECT * FROM users WHERE email = $1", email)
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) GetByID(ctx context.Context, id int64) (*model.User, error) {
    var user model.User
    err := r.db.GetContext(ctx, &user, "SELECT * FROM users WHERE id = $1", id)
    if err != nil {
        return nil, err
    }
    return &user, nil
}
```

**post.go:**
```go
package repository

import (
    "context"

    "github.com/jmoiron/sqlx"

    "api-server/internal/model"
)

type PostRepository struct {
    db *sqlx.DB
}

func NewPostRepository(db *sqlx.DB) *PostRepository {
    return &PostRepository{db: db}
}

func (r *PostRepository) Create(ctx context.Context, post *model.Post) error {
    query := `INSERT INTO posts (user_id, title, content) VALUES ($1, $2, $3) RETURNING id, created_at, updated_at`
    return r.db.QueryRowContext(ctx, query, post.UserID, post.Title, post.Content).
        Scan(&post.ID, &post.CreatedAt, &post.UpdatedAt)
}

func (r *PostRepository) GetByID(ctx context.Context, id int64) (*model.Post, error) {
    var post model.Post
    query := `SELECT p.*, u.username FROM posts p JOIN users u ON p.user_id = u.id WHERE p.id = $1`
    err := r.db.GetContext(ctx, &post, query, id)
    if err != nil {
        return nil, err
    }
    return &post, nil
}

func (r *PostRepository) List(ctx context.Context, page, pageSize int) ([]model.Post, int, error) {
    var totalCount int
    err := r.db.GetContext(ctx, &totalCount, "SELECT COUNT(*) FROM posts")
    if err != nil {
        return nil, 0, err
    }

    var posts []model.Post
    query := `SELECT p.*, u.username FROM posts p JOIN users u ON p.user_id = u.id ORDER BY p.created_at DESC LIMIT $1 OFFSET $2`
    err = r.db.SelectContext(ctx, &posts, query, pageSize, (page-1)*pageSize)
    if err != nil {
        return nil, 0, err
    }

    return posts, totalCount, nil
}

func (r *PostRepository) Update(ctx context.Context, post *model.Post) error {
    query := `UPDATE posts SET title = $1, content = $2, updated_at = NOW() WHERE id = $3 AND user_id = $4`
    result, err := r.db.ExecContext(ctx, query, post.Title, post.Content, post.ID, post.UserID)
    if err != nil {
        return err
    }
    rows, _ := result.RowsAffected()
    if rows == 0 {
        return fmt.Errorf("post not found or unauthorized")
    }
    return nil
}

func (r *PostRepository) Delete(ctx context.Context, id, userID int64) error {
    result, err := r.db.ExecContext(ctx, "DELETE FROM posts WHERE id = $1 AND user_id = $2", id, userID)
    if err != nil {
        return err
    }
    rows, _ := result.RowsAffected()
    if rows == 0 {
        return fmt.Errorf("post not found or unauthorized")
    }
    return nil
}
```

**notification.go:**
```go
package repository

import (
    "context"

    "github.com/jmoiron/sqlx"

    "api-server/internal/model"
)

type NotificationRepository struct {
    db *sqlx.DB
}

func NewNotificationRepository(db *sqlx.DB) *NotificationRepository {
    return &NotificationRepository{db: db}
}

func (r *NotificationRepository) Create(ctx context.Context, notif *model.Notification) error {
    query := `INSERT INTO notifications (user_id, type, message, ref_id) VALUES ($1, $2, $3, $4) RETURNING id, created_at`
    return r.db.QueryRowContext(ctx, query, notif.UserID, notif.Type, notif.Message, notif.RefID).
        Scan(&notif.ID, &notif.CreatedAt)
}

func (r *NotificationRepository) GetByUserID(ctx context.Context, userID int64) ([]model.Notification, error) {
    var notifications []model.Notification
    query := `SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50`
    err := r.db.SelectContext(ctx, &notifications, query, userID)
    return notifications, err
}

func (r *NotificationRepository) GetUnreadCount(ctx context.Context, userID int64) (int, error) {
    var count int
    err := r.db.GetContext(ctx, &count, "SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false", userID)
    return count, err
}

func (r *NotificationRepository) MarkAsRead(ctx context.Context, id, userID int64) error {
    _, err := r.db.ExecContext(ctx, "UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2", id, userID)
    return err
}

func (r *NotificationRepository) MarkAllAsRead(ctx context.Context, userID int64) error {
    _, err := r.db.ExecContext(ctx, "UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false", userID)
    return err
}
```

### 7. Service 계층 (internal/service/)

**user.go:**
```go
package service

import (
    "context"
    "errors"
    "time"

    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"

    "api-server/internal/model"
    "api-server/internal/repository"
)

type UserService struct {
    repo      *repository.UserRepository
    jwtSecret string
}

func NewUserService(repo *repository.UserRepository, jwtSecret string) *UserService {
    return &UserService{repo: repo, jwtSecret: jwtSecret}
}

func (s *UserService) Register(ctx context.Context, req model.CreateUserRequest) (*model.User, error) {
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
    if err != nil {
        return nil, err
    }

    user := &model.User{
        Email:    req.Email,
        Username: req.Username,
        Password: string(hashedPassword),
    }

    if err := s.repo.Create(ctx, user); err != nil {
        return nil, errors.New("email or username already exists")
    }

    return user, nil
}

func (s *UserService) Login(ctx context.Context, req model.LoginRequest) (*model.LoginResponse, error) {
    user, err := s.repo.GetByEmail(ctx, req.Email)
    if err != nil {
        return nil, errors.New("invalid email or password")
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
        return nil, errors.New("invalid email or password")
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "user_id": user.ID,
        "exp":     time.Now().Add(24 * time.Hour).Unix(),
    })

    tokenString, err := token.SignedString([]byte(s.jwtSecret))
    if err != nil {
        return nil, err
    }

    return &model.LoginResponse{Token: tokenString, User: *user}, nil
}

func (s *UserService) GetByID(ctx context.Context, id int64) (*model.User, error) {
    return s.repo.GetByID(ctx, id)
}
```

**post.go:**
```go
package service

import (
    "context"

    "api-server/internal/model"
    "api-server/internal/repository"
)

type PostService struct {
    postRepo *repository.PostRepository
    notifSvc *NotificationService
}

func NewPostService(postRepo *repository.PostRepository, notifSvc *NotificationService) *PostService {
    return &PostService{postRepo: postRepo, notifSvc: notifSvc}
}

func (s *PostService) Create(ctx context.Context, userID int64, req model.CreatePostRequest) (*model.Post, error) {
    post := &model.Post{
        UserID:  userID,
        Title:   req.Title,
        Content: req.Content,
    }

    if err := s.postRepo.Create(ctx, post); err != nil {
        return nil, err
    }

    return post, nil
}

func (s *PostService) GetByID(ctx context.Context, id int64) (*model.Post, error) {
    return s.postRepo.GetByID(ctx, id)
}

func (s *PostService) List(ctx context.Context, page, pageSize int) (*model.PostListResponse, error) {
    if page < 1 {
        page = 1
    }
    if pageSize < 1 || pageSize > 100 {
        pageSize = 20
    }

    posts, totalCount, err := s.postRepo.List(ctx, page, pageSize)
    if err != nil {
        return nil, err
    }

    return &model.PostListResponse{
        Posts:      posts,
        TotalCount: totalCount,
        Page:       page,
        PageSize:   pageSize,
    }, nil
}

func (s *PostService) Update(ctx context.Context, id, userID int64, req model.UpdatePostRequest) (*model.Post, error) {
    post, err := s.postRepo.GetByID(ctx, id)
    if err != nil {
        return nil, err
    }

    if req.Title != nil {
        post.Title = *req.Title
    }
    if req.Content != nil {
        post.Content = *req.Content
    }

    if err := s.postRepo.Update(ctx, post); err != nil {
        return nil, err
    }

    return post, nil
}

func (s *PostService) Delete(ctx context.Context, id, userID int64) error {
    return s.postRepo.Delete(ctx, id, userID)
}
```

**notification.go:**
```go
package service

import (
    "context"
    "fmt"

    "api-server/internal/model"
    "api-server/internal/repository"
)

type NotificationService struct {
    repo *repository.NotificationRepository
}

func NewNotificationService(repo *repository.NotificationRepository) *NotificationService {
    return &NotificationService{repo: repo}
}

func (s *NotificationService) CreatePostNotification(ctx context.Context, userID, postID int64, postTitle string) error {
    notif := &model.Notification{
        UserID:  userID,
        Type:    "new_post",
        Message: fmt.Sprintf("새 게시글이 작성되었습니다: %s", postTitle),
        RefID:   &postID,
    }
    return s.repo.Create(ctx, notif)
}

func (s *NotificationService) GetNotifications(ctx context.Context, userID int64) (*model.NotificationListResponse, error) {
    notifications, err := s.repo.GetByUserID(ctx, userID)
    if err != nil {
        return nil, err
    }

    unreadCount, err := s.repo.GetUnreadCount(ctx, userID)
    if err != nil {
        return nil, err
    }

    return &model.NotificationListResponse{
        Notifications: notifications,
        UnreadCount:   unreadCount,
    }, nil
}

func (s *NotificationService) MarkAsRead(ctx context.Context, id, userID int64) error {
    return s.repo.MarkAsRead(ctx, id, userID)
}

func (s *NotificationService) MarkAllAsRead(ctx context.Context, userID int64) error {
    return s.repo.MarkAllAsRead(ctx, userID)
}
```

### 8. 미들웨어 (internal/middleware/auth.go)

```go
package middleware

import (
    "net/http"
    "strings"

    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "authorization header required"})
            c.Abort()
            return
        }

        parts := strings.SplitN(authHeader, " ", 2)
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
            c.Abort()
            return
        }

        token, err := jwt.Parse(parts[1], func(token *jwt.Token) (interface{}, error) {
            if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
                return nil, jwt.ErrSignatureInvalid
            }
            return []byte(jwtSecret), nil
        })

        if err != nil || !token.Valid {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
            c.Abort()
            return
        }

        claims, ok := token.Claims.(jwt.MapClaims)
        if !ok {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token claims"})
            c.Abort()
            return
        }

        userID := int64(claims["user_id"].(float64))
        c.Set("user_id", userID)
        c.Next()
    }
}
```

### 9. 핸들러 (internal/handler/)

**user.go:**
```go
package handler

import (
    "net/http"

    "github.com/gin-gonic/gin"

    "api-server/internal/model"
    "api-server/internal/service"
)

type UserHandler struct {
    svc *service.UserService
}

func NewUserHandler(svc *service.UserService) *UserHandler {
    return &UserHandler{svc: svc}
}

func (h *UserHandler) Register(c *gin.Context) {
    var req model.CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    user, err := h.svc.Register(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, user)
}

func (h *UserHandler) Login(c *gin.Context) {
    var req model.LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    resp, err := h.svc.Login(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) GetProfile(c *gin.Context) {
    userID := c.GetInt64("user_id")

    user, err := h.svc.GetByID(c.Request.Context(), userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
        return
    }

    c.JSON(http.StatusOK, user)
}
```

**post.go:**
```go
package handler

import (
    "net/http"
    "strconv"

    "github.com/gin-gonic/gin"

    "api-server/internal/model"
    "api-server/internal/service"
)

type PostHandler struct {
    svc *service.PostService
}

func NewPostHandler(svc *service.PostService) *PostHandler {
    return &PostHandler{svc: svc}
}

func (h *PostHandler) Create(c *gin.Context) {
    var req model.CreatePostRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID := c.GetInt64("user_id")
    post, err := h.svc.Create(c.Request.Context(), userID, req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, post)
}

func (h *PostHandler) GetByID(c *gin.Context) {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid post id"})
        return
    }

    post, err := h.svc.GetByID(c.Request.Context(), id)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "post not found"})
        return
    }

    c.JSON(http.StatusOK, post)
}

func (h *PostHandler) List(c *gin.Context) {
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

    resp, err := h.svc.List(c.Request.Context(), page, pageSize)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, resp)
}

func (h *PostHandler) Update(c *gin.Context) {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid post id"})
        return
    }

    var req model.UpdatePostRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID := c.GetInt64("user_id")
    post, err := h.svc.Update(c.Request.Context(), id, userID, req)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, post)
}

func (h *PostHandler) Delete(c *gin.Context) {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid post id"})
        return
    }

    userID := c.GetInt64("user_id")
    if err := h.svc.Delete(c.Request.Context(), id, userID); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusNoContent, nil)
}
```

**notification.go:**
```go
package handler

import (
    "net/http"
    "strconv"

    "github.com/gin-gonic/gin"

    "api-server/internal/service"
)

type NotificationHandler struct {
    svc *service.NotificationService
}

func NewNotificationHandler(svc *service.NotificationService) *NotificationHandler {
    return &NotificationHandler{svc: svc}
}

func (h *NotificationHandler) List(c *gin.Context) {
    userID := c.GetInt64("user_id")

    resp, err := h.svc.GetNotifications(c.Request.Context(), userID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, resp)
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
    id, err := strconv.ParseInt(c.Param("id"), 10, 64)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid notification id"})
        return
    }

    userID := c.GetInt64("user_id")
    if err := h.svc.MarkAsRead(c.Request.Context(), id, userID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "marked as read"})
}

func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
    userID := c.GetInt64("user_id")

    if err := h.svc.MarkAllAsRead(c.Request.Context(), userID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "all notifications marked as read"})
}
```

### 10. 라우터 (internal/router/router.go)

```go
package router

import (
    "github.com/gin-gonic/gin"

    "api-server/internal/handler"
    "api-server/internal/middleware"
)

func Setup(
    userHandler *handler.UserHandler,
    postHandler *handler.PostHandler,
    notifHandler *handler.NotificationHandler,
    jwtSecret string,
) *gin.Engine {
    r := gin.Default()

    // Health check
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    api := r.Group("/api/v1")
    {
        // Public routes
        api.POST("/register", userHandler.Register)
        api.POST("/login", userHandler.Login)
        api.GET("/posts", postHandler.List)
        api.GET("/posts/:id", postHandler.GetByID)

        // Protected routes
        auth := api.Group("")
        auth.Use(middleware.AuthMiddleware(jwtSecret))
        {
            auth.GET("/profile", userHandler.GetProfile)

            auth.POST("/posts", postHandler.Create)
            auth.PUT("/posts/:id", postHandler.Update)
            auth.DELETE("/posts/:id", postHandler.Delete)

            auth.GET("/notifications", notifHandler.List)
            auth.PUT("/notifications/:id/read", notifHandler.MarkAsRead)
            auth.PUT("/notifications/read-all", notifHandler.MarkAllAsRead)
        }
    }

    return r
}
```

### 11. 메인 진입점 (cmd/server/main.go)

```go
package main

import (
    "log"

    "api-server/internal/config"
    "api-server/internal/database"
    "api-server/internal/handler"
    "api-server/internal/repository"
    "api-server/internal/router"
    "api-server/internal/service"
)

func main() {
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("Failed to load config: %v", err)
    }

    db, err := database.Connect(cfg)
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }
    defer db.Close()

    // Repositories
    userRepo := repository.NewUserRepository(db)
    postRepo := repository.NewPostRepository(db)
    notifRepo := repository.NewNotificationRepository(db)

    // Services
    notifSvc := service.NewNotificationService(notifRepo)
    userSvc := service.NewUserService(userRepo, cfg.JWTSecret)
    postSvc := service.NewPostService(postRepo, notifSvc)

    // Handlers
    userHandler := handler.NewUserHandler(userSvc)
    postHandler := handler.NewPostHandler(postSvc)
    notifHandler := handler.NewNotificationHandler(notifSvc)

    // Router
    r := router.Setup(userHandler, postHandler, notifHandler, cfg.JWTSecret)

    log.Printf("Server starting on port %s", cfg.ServerPort)
    if err := r.Run(":" + cfg.ServerPort); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}
```

### 12. 마이그레이션 SQL

**migrations/001_create_users.sql:**
```sql
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

**migrations/002_create_posts.sql:**
```sql
CREATE TABLE IF NOT EXISTS posts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
```

**migrations/003_create_notifications.sql:**
```sql
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    ref_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
```

---

## API 엔드포인트 요약

| Method | Endpoint | Auth | 설명 |
|--------|----------|------|------|
| POST | `/api/v1/register` | No | 회원가입 |
| POST | `/api/v1/login` | No | 로그인 (JWT 발급) |
| GET | `/api/v1/profile` | Yes | 내 프로필 조회 |
| GET | `/api/v1/posts` | No | 게시글 목록 (페이지네이션) |
| GET | `/api/v1/posts/:id` | No | 게시글 상세 |
| POST | `/api/v1/posts` | Yes | 게시글 작성 |
| PUT | `/api/v1/posts/:id` | Yes | 게시글 수정 (본인만) |
| DELETE | `/api/v1/posts/:id` | Yes | 게시글 삭제 (본인만) |
| GET | `/api/v1/notifications` | Yes | 알림 목록 + 읽지 않은 수 |
| PUT | `/api/v1/notifications/:id/read` | Yes | 알림 읽음 처리 |
| PUT | `/api/v1/notifications/read-all` | Yes | 전체 알림 읽음 처리 |

## 실행 방법

```bash
# PostgreSQL DB 생성
createdb api_server

# 마이그레이션 실행
psql -d api_server -f migrations/001_create_users.sql
psql -d api_server -f migrations/002_create_posts.sql
psql -d api_server -f migrations/003_create_notifications.sql

# 서버 실행
go run cmd/server/main.go
```

## 테스트 예시

```bash
# 회원가입
curl -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"testuser","password":"password123"}'

# 로그인
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# 게시글 작성 (토큰 필요)
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"첫 게시글","content":"안녕하세요!"}'

# 게시글 목록
curl http://localhost:8080/api/v1/posts?page=1&page_size=10
```

이렇게 기본 구조를 잡았습니다. 실제 프로젝트로 파일을 생성하기 시작할까요? 추가로 필요한 기능이 있으면 알려주세요. 댓글 기능, 검색, 파일 업로드 등도 추가할 수 있습니다.
