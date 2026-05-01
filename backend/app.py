from flask import Flask
import os
from backend.models import db
from backend.routes import users_bp, friends_bp, cookbooks_bp, recipes_bp

def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024
    
    # Configuration with enviromental variables
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    instance_dir = os.path.join(backend_dir, "instance")
    os.makedirs(instance_dir, exist_ok=True)
    db_filename = os.path.join(instance_dir, "inmybeli.db")
    app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
        "DATABASE_URL", 
        f"sqlite:///{db_filename}"
    )
    
    # Initialize database
    db.init_app(app)
    
    with app.app_context():
        db.create_all()
    
    # Register blueprints
    app.register_blueprint(users_bp, url_prefix="/api/users")
    app.register_blueprint(friends_bp, url_prefix="/api/friends")
    app.register_blueprint(cookbooks_bp, url_prefix= "/api/cookbooks")
    app.register_blueprint(recipes_bp, url_prefix="/api")
    
    return app
 
if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
 