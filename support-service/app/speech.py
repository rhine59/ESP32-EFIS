import os
import httpx

STT_BASE=os.getenv("STT_BASE_URL","").rstrip("/")
STT_KEY=os.getenv("STT_API_KEY","")
STT_MODEL=os.getenv("STT_MODEL","")
TTS_BASE=os.getenv("TTS_BASE_URL","").rstrip("/")
TTS_KEY=os.getenv("TTS_API_KEY","")
TTS_MODEL=os.getenv("TTS_MODEL","")
TTS_VOICE=os.getenv("TTS_VOICE","")
TIMEOUT=float(os.getenv("SPEECH_TIMEOUT_SECONDS","30"))
MAX_AUDIO=int(os.getenv("MAX_AUDIO_BYTES","10000000"))

def transcribe(audio:bytes, filename:str, content_type:str, language:str|None=None):
    if not (STT_BASE and STT_KEY and STT_MODEL):
        return None,"speech-to-text is not configured"
    if not audio or len(audio)>MAX_AUDIO:
        return None,"audio is empty or exceeds the configured limit"
    data={"model":STT_MODEL}
    if language: data["language"]=language
    try:
        with httpx.Client(timeout=TIMEOUT) as h:
            r=h.post(f"{STT_BASE}/audio/transcriptions",
                headers={"Authorization":f"Bearer {STT_KEY}"},
                data=data,files={"file":(filename,audio,content_type)})
            r.raise_for_status()
            text=r.json().get("text","").strip()
            return (text,None) if text else (None,"empty transcription")
    except Exception:
        return None,"speech-to-text service unavailable"

def synthesize(text:str):
    if not (TTS_BASE and TTS_KEY and TTS_MODEL and TTS_VOICE):
        return None,None,"text-to-speech is not configured"
    try:
        with httpx.Client(timeout=TIMEOUT) as h:
            r=h.post(f"{TTS_BASE}/audio/speech",
                headers={"Authorization":f"Bearer {TTS_KEY}","Content-Type":"application/json"},
                json={"model":TTS_MODEL,"voice":TTS_VOICE,"input":text[:6000],"response_format":"mp3"})
            r.raise_for_status()
            return r.content,r.headers.get("content-type","audio/mpeg"),None
    except Exception:
        return None,None,"text-to-speech service unavailable"
