from pathlib import Path
from setuptools import setup, find_packages

this_dir = Path(__file__).parent.resolve()
long_description = (this_dir / "logwatch_ai_README.md").read_text(encoding="utf-8")

setup(
    name="logwatch-agent",
    version="2.0.1",
    author="Ahmed Dridi",
    author_email="[EMAIL_ADDRESS]",
    description="Lightweight cloud agent for Windows Event Log anomaly detection",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ahmed0220arch/Windows-Logs-ai-anomaly-detect-System",
    packages=find_packages(),
    install_requires=[
        "requests",
        "psutil",
        "pywin32",
        "pyyaml",
    ],
    entry_points={
        "console_scripts": [
            "logwatch-ai=logwatch_ai.cli:main",
        ],
    },
    python_requires=">=3.10",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: Microsoft :: Windows",
        "Topic :: Security",
        "Topic :: System :: Logging",
    ],
)
