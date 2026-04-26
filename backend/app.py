from flask import Flask
import os
from backend.models import db
from backend.routes import auth_bp, users_bp

 
def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)
    
    # Configuration with enviromental variables
    db_filename = "inmybeli.db"
    app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
        "DATABASE_URL", 
        f"sqlite:///{db_filename}"
    )
    
    # Initialize database
    db.init_app(app)
    
    with app.app_context():
        # this is here for just testing purposes
        db.drop_all()
        db.create_all()
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix="/api/users")
    app.register_blueprint(users_bp, url_prefix="/api/users")
    
    return app
 
if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
 