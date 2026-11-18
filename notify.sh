#!/bin/bash
CONTACTEMAIL=$1
NOTIFICATIONTYPE=$2
HOSTALIAS=$3
SERVICEDESC=$4
STATE=$5
HOSTADDRESS=$6

# ---- CONFIGURATION DES SECRETS (Utilise des placeholders pour GitHub) ----
TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-VOTRE_TOKEN_TELEGRAM}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-VOTRE_CHAT_ID}"

# WhatsApp via GREEN-API
GREEN_API_URL="${GREEN_API_URL:-https://7107.api.greenapi.com}"
GREEN_ID="${GREEN_ID:-VOTRE_ID_INSTANCE}"
GREEN_TOKEN="${GREEN_TOKEN:-VOTRE_TOKEN_GREEN_API}"
WA_PHONE="${WA_PHONE:-VOTRE_NUMERO}"

REAL_EMAIL="${REAL_EMAIL:-votre_email@gmail.com}"
GMAIL_USER="${GMAIL_USER:-votre_email@gmail.com}"
GMAIL_APP_PASSWORD="${GMAIL_APP_PASSWORD:-VOTRE_MOT_DE_PASSE_APPLICATION}"
# -----------------------------------------------------------------

LOGFILE=${LOGFILE:-/opt/nagios/var/notifications.log}
DATE_LOG=$(date '+%Y-%m-%d %H:%M:%S')
DATE_JOLIE=$(date '+%d/%m/%Y à %H:%M:%S')

html_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g'
}

# ---------- Rédaction du message ----------
if [ "$SERVICEDESC" = "HOST" ]; then
  LIBELLE_SERVICE="Machine entière (ping)"
  case "$STATE" in
    DOWN)
      EMOJI="🔴"
      COULEUR="#d9534f"
      BANDEAU="ALERTE CRITIQUE"
      ETAT_FR="HORS SERVICE"
      TITRE="ALERTE : $HOSTALIAS est hors service"
      DETAIL="L'équipement $HOSTALIAS ($HOSTADDRESS) ne répond plus du tout. Une intervention est nécessaire !"
      ACTION="Vérifier l'alimentation, la connexion réseau et le service concerné." ;;
    UNREACHABLE)
      EMOJI="🟠"
      COULEUR="#f0ad4e"
      BANDEAU="ÉQUIPEMENT INJOIGNABLE"
      ETAT_FR="INJOIGNABLE"
      TITRE="$HOSTALIAS est injoignable"
      DETAIL="Impossible d'atteindre $HOSTALIAS ($HOSTADDRESS) : un équipement en amont (routeur ?) semble être en panne."
      ACTION="Vérifier l'équipement en amont (routeur ou passerelle)." ;;
    UP)
      EMOJI="✅"
      COULEUR="#28a745"
      BANDEAU="RETOUR À LA NORMALE"
      ETAT_FR="EN LIGNE"
      TITRE="Retour à la normale : $HOSTALIAS"
      DETAIL="Bonne nouvelle ! $HOSTALIAS ($HOSTADDRESS) répond de nouveau correctement. 🎉"
      ACTION="Aucune action requise, tout est rentré dans l'ordre." ;;
    *)
      EMOJI="ℹ️"
      COULEUR="#5bc0de"
      BANDEAU="INFORMATION"
      ETAT_FR="$STATE"
      TITRE="Information sur $HOSTALIAS"
      DETAIL="L'équipement $HOSTALIAS ($HOSTADDRESS) est dans l'état : $STATE."
      ACTION="Consulter l'interface Nagios pour plus de détails." ;;
  esac
else
  SERVICE_JOLI="${SERVICEDESC//_/ }"
  LIBELLE_SERVICE="$SERVICE_JOLI"
  case "$STATE" in
    CRITICAL)
      EMOJI="🔴"
      COULEUR="#d9534f"
      BANDEAU="SERVICE EN PANNE"
      ETAT_FR="CRITIQUE"
      TITRE="ALERTE : le service « $SERVICE_JOLI » est en panne sur $HOSTALIAS"
      DETAIL="Le service « $SERVICE_JOLI » de $HOSTALIAS ($HOSTADDRESS) est en état critique. Vérifiez-le rapidement !"
      ACTION="Vérifier le service et consulter ses journaux." ;;
    WARNING)
      EMOJI="🟡"
      COULEUR="#f0ad4e"
      BANDEAU="SERVICE DÉGRADÉ"
      ETAT_FR="ATTENTION"
      TITRE="Attention : le service « $SERVICE_JOLI » est dégradé sur $HOSTALIAS"
      DETAIL="Le service « $SERVICE_JOLI » de $HOSTALIAS ($HOSTADDRESS) montre des signes de faiblesse."
      ACTION="Surveiller le service : une dégradation est en cours." ;;
    UNKNOWN)
      EMOJI="🟠"
      COULEUR="#f0ad4e"
      BANDEAU="ÉTAT INCONNU"
      ETAT_FR="INCONNU"
      TITRE="Service « $SERVICE_JOLI » : état inconnu sur $HOSTALIAS"
      DETAIL="Nagios n'arrive pas à déterminer l'état du service « $SERVICE_JOLI » sur $HOSTALIAS ($HOSTADDRESS)."
      ACTION="Vérifier que la sonde Nagios fonctionne correctement." ;;
    OK)
      EMOJI="✅"
      COULEUR="#28a745"
      BANDEAU="SERVICE RÉTABLI"
      ETAT_FR="OPÉRATIONNEL"
      TITRE="Retour à la normale : « $SERVICE_JOLI » sur $HOSTALIAS"
      DETAIL="Tout va bien ! Le service « $SERVICE_JOLI » de $HOSTALIAS ($HOSTADDRESS) fonctionne de nouveau. 🎉"
      ACTION="Aucune action requise." ;;
    *)
      EMOJI="ℹ️"
      COULEUR="#5bc0de"
      BANDEAU="INFORMATION"
      ETAT_FR="$STATE"
      TITRE="Information sur « $SERVICE_JOLI » ($HOSTALIAS)"
      DETAIL="Le service « $SERVICE_JOLI » de $HOSTALIAS est dans l'état : $STATE."
      ACTION="Consulter l'interface Nagios pour plus de détails." ;;
  esac
fi

case "$NOTIFICATIONTYPE" in
  PROBLEM)         TYPE_FR="Problème détecté" ;;
  RECOVERY)        TYPE_FR="Rétablissement" ;;
  ACKNOWLEDGEMENT) TYPE_FR="Prise en compte" ;;
  CUSTOM)          TYPE_FR="Notification manuelle" ;;
  *)               TYPE_FR="$NOTIFICATIONTYPE" ;;
esac

SUBJECT="$EMOJI $TITRE"

# Message court (WhatsApp, Telegram) avec mise en forme
COURT="$EMOJI *$BANDEAU*
━━━━━━━━━━━━━━━━━━
🖥️ *Équipement :* $HOSTALIAS
🌐 *Adresse :* $HOSTADDRESS
📌 *Service :* $LIBELLE_SERVICE
📊 *État :* $STATE ($ETAT_FR)
🕐 *Date :* $DATE_JOLIE
━━━━━━━━━━━━━━━━━━
💬 _${DETAIL}_
🛠️ *Action :* $ACTION

🤖 _Supervision Nagios_"

# Message texte simple (secours pour l'email)
CORPS="Bonjour,

$DETAIL

Détails :
- Équipement : $HOSTALIAS
- Adresse : $HOSTADDRESS
- Service : $LIBELLE_SERVICE
- État : $STATE ($ETAT_FR)
- Type de notification : $TYPE_FR
- Date : $DATE_JOLIE

Action recommandée : $ACTION

Message envoyé automatiquement par votre supervision Nagios 🤖"

# Valeurs protégées pour le HTML
HOSTALIAS_H=$(html_escape "$HOSTALIAS")
HOSTADDRESS_H=$(html_escape "$HOSTADDRESS")
SERVICE_H=$(html_escape "$LIBELLE_SERVICE")
DETAIL_H=$(html_escape "$DETAIL")
ACTION_H=$(html_escape "$ACTION")
BANDEAU_H=$(html_escape "$BANDEAU")
ETAT_FR_H=$(html_escape "$ETAT_FR")

# Message Telegram (mise en forme HTML)
COURT_TG="$EMOJI <b>$BANDEAU_H</b>
━━━━━━━━━━━━━━━━━━
🖥️ <b>Équipement :</b> $HOSTALIAS_H
🌐 <b>Adresse :</b> <code>$HOSTADDRESS_H</code>
📌 <b>Service :</b> $SERVICE_H
📊 <b>État :</b> <code>$STATE</code> ($ETAT_FR_H)
🕐 <b>Date :</b> $DATE_JOLIE
━━━━━━━━━━━━━━━━━━
<blockquote>💬 $DETAIL_H
🛠️ <b>Action :</b> $ACTION_H</blockquote>
🤖 <i>Supervision Nagios</i>"

construire_html() {
cat <<HTML
<html>
<body style="margin:0;padding:0;background:#f4f6f8;font-family:'Segoe UI',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f8;padding:24px 0;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;overflow:hidden;">
<tr><td style="background:$COULEUR;padding:28px 24px;text-align:center;color:#ffffff;">
<div style="font-size:44px;line-height:52px;">$EMOJI</div>
<div style="font-size:22px;font-weight:bold;letter-spacing:1px;margin-top:6px;">$BANDEAU_H</div>
</td></tr>
<tr><td style="padding:26px 28px 8px 28px;color:#333333;font-size:15px;line-height:1.6;">
<p style="margin:0 0 12px 0;">Bonjour,</p>
<p style="margin:0 0 18px 0;">$DETAIL_H</p>
</td></tr>
<tr><td style="padding:0 28px 8px 28px;">
<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e3e7eb;border-radius:8px;font-size:14px;color:#333333;">
<tr><td style="padding:10px 14px;background:#f8f9fa;width:38%;border-bottom:1px solid #e3e7eb;">🖥️ <b>Équipement</b></td><td style="padding:10px 14px;border-bottom:1px solid #e3e7eb;">$HOSTALIAS_H</td></tr>
<tr><td style="padding:10px 14px;background:#f8f9fa;border-bottom:1px solid #e3e7eb;">🌐 <b>Adresse</b></td><td style="padding:10px 14px;border-bottom:1px solid #e3e7eb;">$HOSTADDRESS_H</td></tr>
<tr><td style="padding:10px 14px;background:#f8f9fa;border-bottom:1px solid #e3e7eb;">📌 <b>Service</b></td><td style="padding:10px 14px;border-bottom:1px solid #e3e7eb;">$SERVICE_H</td></tr>
<tr><td style="padding:10px 14px;background:#f8f9fa;border-bottom:1px solid #e3e7eb;">📊 <b>État</b></td><td style="padding:10px 14px;border-bottom:1px solid #e3e7eb;"><span style="background:$COULEUR;color:#ffffff;padding:3px 12px;border-radius:12px;font-weight:bold;">$STATE &middot; $ETAT_FR</span></td></tr>
<tr><td style="padding:10px 14px;background:#f8f9fa;border-bottom:1px solid #e3e7eb;">🔔 <b>Notification</b></td><td style="padding:10px 14px;border-bottom:1px solid #e3e7eb;">$TYPE_FR</td></tr>
<tr><td style="padding:10px 14px;background:#f8f9fa;">🕐 <b>Date</b></td><td style="padding:10px 14px;">$DATE_JOLIE</td></tr>
</table>
</td></tr>
<tr><td style="padding:18px 28px 26px 28px;">
<div style="border-left:4px solid $COULEUR;background:#f8f9fa;padding:12px 16px;font-size:14px;color:#333333;">
🛠️ <b>Action recommandée :</b> $ACTION_H
</div>
</td></tr>
<tr><td style="background:#2b2f36;padding:16px;text-align:center;color:#aab2bd;font-size:12px;">
🤖 Message envoyé automatiquement par votre supervision Nagios
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>
HTML
}

# ---------- 1. Journal local ----------
echo "$DATE_LOG [Nagios Alert] Type: $NOTIFICATIONTYPE | Host: $HOSTALIAS ($HOSTADDRESS) | Service: $SERVICEDESC | State: $STATE" >> "$LOGFILE"

# ---------- 2. Email (texte + HTML) ----------
SUBJECT_B64=$(printf '%s' "$SUBJECT" | base64 -w0)

construire_mail() {
  BOUNDARY="----=_NagiosPart_$(date +%s)_$$"
  {
    printf 'From: Supervision Nagios <%s>\n' "$1"
    printf 'To: %s\n' "$2"
    printf 'Subject: =?UTF-8?B?%s?=\n' "$SUBJECT_B64"
    printf 'MIME-Version: 1.0\n'
    printf 'Content-Type: multipart/alternative; boundary="%s"\n' "$BOUNDARY"
    printf '\n'
    printf -- '--%s\n' "$BOUNDARY"
    printf 'Content-Type: text/plain; charset=UTF-8\n'
    printf 'Content-Transfer-Encoding: 8bit\n'
    printf '\n'
    printf '%s\n' "$CORPS"
    printf -- '--%s\n' "$BOUNDARY"
    printf 'Content-Type: text/html; charset=UTF-8\n'
    printf 'Content-Transfer-Encoding: 8bit\n'
    printf '\n'
    construire_html
    printf -- '--%s--\n' "$BOUNDARY"
  } | sed 's/$/\r/'
}

# 2a. MailHog (boîte de test locale)
construire_mail "nagios@localhost" "$CONTACTEMAIL" | \
  curl -sS --max-time 10 --url "smtp://mailhog:1025" \
  --mail-from "nagios@localhost" --mail-rcpt "$CONTACTEMAIL" -T - \
  >> "$LOGFILE" 2>&1

# 2b. Vraie boîte mail via Gmail (seulement si rempli)
if [ "$GMAIL_APP_PASSWORD" != "VOTRE_MOT_DE_PASSE_APPLICATION" ] && [ "$REAL_EMAIL" != "votre_email@gmail.com" ]; then
  construire_mail "$GMAIL_USER" "$REAL_EMAIL" | \
    curl -sS --max-time 20 --url "smtps://smtp.gmail.com:465" --ssl-reqd \
    --mail-from "$GMAIL_USER" --mail-rcpt "$REAL_EMAIL" \
    --user "$GMAIL_USER:$GMAIL_APP_PASSWORD" -T - \
    >> "$LOGFILE" 2>&1
fi

# ---------- 3. Telegram ----------
if [ "$TELEGRAM_TOKEN" != "VOTRE_TOKEN_TELEGRAM" ] && [ "$TELEGRAM_CHAT_ID" != "VOTRE_CHAT_ID" ]; then
  TG_REP=$(curl -sS --max-time 10 -X POST \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    --data-urlencode text="$COURT_TG" 2>&1)
  case "$TG_REP" in
    *'"ok":true'*)
      echo "$DATE_LOG [Telegram] message envoyé" >> "$LOGFILE" ;;
    *)
      echo "$DATE_LOG [Telegram] échec de la version mise en forme, nouvel essai en texte simple : ${TG_REP:0:150}" >> "$LOGFILE"
      curl -sS --max-time 10 -X POST \
        "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        --data-urlencode text="$CORPS" > /dev/null 2>&1 ;;
  esac
fi

# ---------- 4. WhatsApp via GREEN-API ----------
if [ "$GREEN_TOKEN" != "VOTRE_TOKEN_GREEN_API" ] && [ "$GREEN_ID" != "VOTRE_ID_INSTANCE" ]; then
  MSG_JSON=$(printf '%s' "$COURT" | sed ':a;N;$!ba;s/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g')
  PHONE_CLEAN="${WA_PHONE#+}"
  echo "$DATE_LOG [WhatsApp GREEN-API] envoi vers ${PHONE_CLEAN}" >> "$LOGFILE"
  curl -sS --max-time 20 -X POST \
    "${GREEN_API_URL}/waInstance${GREEN_ID}/sendMessage/${GREEN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"chatId\":\"${PHONE_CLEAN}@c.us\",\"message\":\"${MSG_JSON}\"}" >> "$LOGFILE" 2>&1
  echo "" >> "$LOGFILE"
fi